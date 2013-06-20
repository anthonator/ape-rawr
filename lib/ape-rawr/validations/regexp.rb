module ApeRawr
  module Validations
    class RegexpValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        if params[attr_name] && !( params[attr_name].to_s =~ @option )
          error!(:invalid_parmeter, :attribute => attr_name)
        end
      end
    end
  end
end
