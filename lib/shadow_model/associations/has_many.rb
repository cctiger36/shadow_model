class ::ActiveRecord::Associations::Builder::HasMany
  if self.instance_methods.include?(:valid_options=)
    self.valid_options += [:shadow]
  else
    def valid_options_with_shadow_option
      valid_options_without_shadow_option + [:shadow]
    end
    alias_method_chain :valid_options, :shadow_option
  end

  def build_with_shadow_option
    reflection = build_without_shadow_option
    if options[:shadow]
      model_name = model.name.tr('::', '').underscore
      define_shadow_methods_of_model_class(reflection, model_name)
      define_shadow_methods_of_reflection_class(reflection, model_name)
    end
    reflection
  end
  alias_method_chain :build, :shadow_option

  private

  def define_shadow_methods_of_model_class(reflection, model_name)
    model.class_eval <<-RUBY
      def #{name}_shadow_cache_key
        "#{model_name}_\#{self[self.class.primary_key]}_#{name}_shadow_cache"
      end

      def #{name}_by_shadow
        Redis.current.hvals(#{name}_shadow_cache_key).map do |val|
          shadow_data = Marshal.load(val)
          #{reflection.klass.name}.instantiate_shadow_model(shadow_data)
        end
      end

      def clear_#{name}_shadow_cache
        Redis.current.del(#{name}_shadow_cache_key)
      end
    RUBY
  end

  def define_shadow_methods_of_reflection_class(reflection, model_name)
    reflection.klass.class_eval <<-RUBY
      after_save :update_shadow_cache_of_#{model_name}
      after_destroy :delete_shadow_cache_of_#{model_name}

      def belongs_to_#{model_name}_shadow_cache_key
        "#{model_name}_\#{self[:#{reflection.foreign_key}]}_#{name}_shadow_cache"
      end

      def update_shadow_cache_of_#{model_name}
        cache_key = belongs_to_#{model_name}_shadow_cache_key
        Redis.current.hset(cache_key, self[self.class.primary_key], self.build_shadow_data)
        update_expiration(cache_key)
      end

      def delete_shadow_cache_of_#{model_name}
        Redis.current.hdel(belongs_to_#{model_name}_shadow_cache_key, self[self.class.primary_key])
      end
    RUBY
  end
end
