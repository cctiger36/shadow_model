require 'active_support'
require 'active_record'
require 'shadow_model/version'

module ShadowModel
  extend ActiveSupport::Concern

  autoload :ModelExtension, 'shadow_model/model_extension'
  
  module ClassMethods
    def shadow_model(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      self.send :include, ShadowModel::ModelExtension
      set_shadow_keys(args, options)
    end
  end
end

ActiveRecord::Base.send :include, ShadowModel

require 'shadow_model/associations/has_many'
