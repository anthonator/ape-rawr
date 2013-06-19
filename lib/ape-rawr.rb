require "ape-rawr/version"
require "ape-rawr/error_registrar"
require "ape-rawr/controller/error_handling"

ActiveSupport.on_load(:action_controller) do
  include ApeRawr::ErrorHandling
end
