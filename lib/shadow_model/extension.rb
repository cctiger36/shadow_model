module ShadowModel
  module Extension
    def self.included(base)
      base.class_eval <<-RUBY
        mattr_accessor :shadow_attributes
        mattr_accessor :shadow_methods
        extend ClassMethods
        after_save :update_shadow_cache
      RUBY
    end

    def shadow_model?
      @shadow_model
    end

    def shadow_model=(value)
      @shadow_model = value
    end

    def shadow_cache_key
      self.class.build_shadow_cache_key self[self.class.primary_key]
    end

    def shadow_data
      @shadow_data ||= self.class.find_shadow_data(self[self.class.primary_key])
    end

    def shadow_data=(data)
      @shadow_data = data
    end

    def clear_shadow_data
      Redis.current.del(shadow_cache_key)
    end

    def build_shadow_data
      Marshal.dump(self.class.shadow_keys.inject({}) { |data, attr| data[attr] = send(attr); data })
    end

    def update_shadow_cache
      Redis.current.set(shadow_cache_key, build_shadow_data)
    end

    module ClassMethods
      def set_shadow_keys(args, options = {})
        @shadow_attributes ||= []
        @shadow_methods ||= []
        args.each do |arg|
          if self.attribute_names.include?(arg.to_s)
            @shadow_attributes << arg.to_sym
          else
            @shadow_methods << arg.to_sym
          end
        end
        @shadow_attributes.each { |attr| define_shadow_attributes(attr) }
      end

      def shadow_keys
        @shadow_attributes + @shadow_methods
      end

      def method_added(method_name)
        define_shadow_methods(method_name)
      end

      def define_shadow_attributes(attribute_name)
        self.class_eval <<-RUBY
          def #{attribute_name}_without_shadow
            self.read_attribute(:#{attribute_name})
          end

          def #{attribute_name}
            shadow_model? ? shadow_data[:#{attribute_name}] : #{attribute_name}_without_shadow
          end
        RUBY
      end

      def define_shadow_methods(method_name)
        if self.shadow_keys.include?(method_name.to_sym) && !self.instance_methods.include?("#{method_name}_without_shadow".to_sym)
          self.class_eval <<-RUBY
            def #{method_name}_with_shadow
              shadow_model? ? shadow_data[:#{method_name}] : #{method_name}_without_shadow
            end
            alias_method_chain :#{method_name}, :shadow
          RUBY
        end
      end

      # TODO load from database if not found
      def find_by_shadow(id)
        if shadow_data = find_shadow_data(id)
          instance = self.new
          instance.shadow_model = true
          instance.shadow_data = shadow_data
          instance.readonly!
          instance
        else
          nil
        end
      end

      def find_shadow_data(id)
        data = Redis.current.get(build_shadow_cache_key(id))
        data ? Marshal.load(data) : nil
      end

      def build_shadow_cache_key(id)
        "#{self.name.tableize}:Shadow:#{id}"
      end
    end
  end
end
