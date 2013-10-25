module ShadowModel
  module ModelExtension
    def self.included(base)
      base.class_eval <<-RUBY
        mattr_accessor :shadow_options
        extend ClassMethods
        after_save :update_shadow_cache
        after_destroy :clear_shadow_data
      RUBY
    end

    module ClassMethods
      def set_shadow_keys(args, options = {})
        @shadow_attributes ||= []
        @shadow_methods ||= []
        self.shadow_options = options
        args.each do |arg|
          if self.attribute_names.include?(arg.to_s)
            @shadow_attributes << arg.to_sym
          else
            @shadow_methods << arg.to_sym
          end
        end
        @shadow_attributes << primary_key.to_sym if !@shadow_attributes.include?(primary_key.to_sym)
        @shadow_attributes.each { |attr| define_shadow_attributes(attr) }
      end

      def shadow_keys
        (@shadow_attributes || []) + (@shadow_methods || [])
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

      def find_by_shadow(id)
        raise "Cannot find seperate shadow cache with association_only option set" if shadow_options[:association_only]
        if shadow_data = find_shadow_data(id)
          instantiate_shadow_model(shadow_data)
        else
          instance = self.find(id)
          instance.update_shadow_cache
          find_by_shadow(id)
        end
      end

      def find_shadow_data(id)
        data = Redis.current.get(build_shadow_cache_key(id))
        data ? Marshal.load(data) : nil
      end

      def instantiate_shadow_model(shadow_data)
        instance = self.new
        instance.instance_variable_set(:@shadow_model, true)
        instance.send(:shadow_data=, shadow_data)
        instance.readonly!
        instance
      end

      def build_shadow_cache_key(id)
        "#{self.name.tableize}:Shadow:#{id}"
      end
    end

    def shadow_model?
      @shadow_model
    end

    def reload
      self.instance_variable_set(:@readonly, false)
      @shadow_model = false
      super
    end

    def shadow_cache_key
      @shadow_cache_key ||= self.class.build_shadow_cache_key(self[self.class.primary_key])
    end

    def shadow_data
      @shadow_data ||= self.class.find_shadow_data(self[self.class.primary_key])
    end

    def clear_shadow_data
      Redis.current.del(shadow_cache_key)
    end

    def build_shadow_data
      Marshal.dump(self.class.shadow_keys.inject({}) { |data, attr| data[attr] = send(attr); data })
    end

    def update_shadow_cache
      return if shadow_options[:association_only]
      Redis.current.set(shadow_cache_key, build_shadow_data)
      update_expiration(shadow_cache_key)
    end

    def update_expiration(cache_key)
      if expiration = shadow_options[:expiration]
        if shadow_options[:update_expiration] || shadow_ttl < 0
          Redis.current.expire(cache_key, expiration)
        end
      elsif expireat = shadow_options[:expireat]
        Redis.current.expireat(cache_key, expireat.to_i) if shadow_ttl < 0
      end
    end

    def shadow_ttl
      Redis.current.ttl(shadow_cache_key)
    end

    private

    def shadow_data=(data)
      @shadow_data = data
      self.class.attribute_names.each do |attribute_name|
        attribute_name = attribute_name.to_sym
        if value = data[attribute_name]
          self[attribute_name] = value
        end
      end
    end
  end
end
