module ApeRawr
  # Makes it easier to both throw named exceptions (corresponding to
  # error states in the response) and to then process the response into
  # something useable in the response.
  #
  # @note Taken from RocketPants
  # @see https://github.com/filtersquad/rocket_pants/blob/master/lib/rocket_pants/controller/error_handling.rb
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from ApeRawr::Error, :with => :render_error
      class_attribute :error_mapping
      self.error_mapping = {}
    end

    module ClassMethods
      # Declares that a given error class (e.g. ActiveRecord::RecordNotFound)
      # should map to a second value - either an Exception class Or, more usefully,
      # a callable object.
      # @param [Class] from the exception class to map from.
      # @param [Class, #call] to the callable to map to, or a callback block.
      def map_error!(from, to = nil, &blk)
        to = (to || blk)
        raise ArgumentError, "Either an option must be provided or a block given." unless to
        error_mapping[from] = (to || blk)
        rescue_from from, :with => :render_error
      end
    end
  end
end
