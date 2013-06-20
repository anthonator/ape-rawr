module ApeRawr
  module Validations
    class PresenceValidator < Validator
      def validate_param!(attr_name, params)
        unless params.has_key?(attr_name)
          error!(:presence, :attribute => attr_name)
        end
      end
    end
  end
end
