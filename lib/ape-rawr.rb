require "i18n"
require "active_support/core_ext/object"
require "active_support/inflector/methods"
require "virtus"
require "hashie"

require "ape-rawr/version"
require "ape-rawr/util/hash_stack"
require "ape-rawr/error_registrar"
require "ape-rawr/error_handler"
require "ape-rawr/error_handling"
require "ape-rawr/validations"

I18n.load_path << File.expand_path('../ape-rawr/locales/en.yml', __FILE__)

ActiveSupport.on_load(:action_controller) do
  include ApeRawr::ErrorHandler
  include ApeRawr::ErrorHandling
  extend ApeRawr::Validations::ClassMethods
end
