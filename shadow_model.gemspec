# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shadow_model/version'

Gem::Specification.new do |spec|
  spec.name          = "shadow_model"
  spec.version       = ShadowModel::VERSION
  spec.authors       = ["Weihu Chen"]
  spec.email         = ["cctiger36@gmail.com"]
  spec.summary       = %q{Rails model cache with redis}
  spec.description   = %q{A rails plugin use reids to cache models data.}
  spec.homepage      = "https://github.com/cctiger36/shadow_model"
  spec.license       = "MIT"

  spec.files         = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 3.1.0"
  spec.add_dependency "redis", ">= 3.0.0"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_girl_rails"
end
