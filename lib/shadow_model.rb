require 'active_support'
require 'active_record'
require 'shadow_model/version'

module ShadowModel
  extend ActiveSupport::Concern

  autoload :Extension, 'shadow_model/extension'
  
  module ClassMethods
    def shadow_model(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      self.send :include, ShadowModel::Extension
      set_shadow_keys(args, options)
    end
  end
end

ActiveRecord::Base.send :include, ShadowModel
