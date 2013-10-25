module ShadowModel
  class Railtie < ::Rails::Railtie
    require 'shadow_model/associations/has_many'
  end
end
