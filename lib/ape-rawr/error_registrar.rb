require 'ape-rawr/error'

module ApeRawr
  # A simple map of data about errors that the ape-rawr system can handle.
  #
  # @note Taken from RocketPants
  # @see https://github.com/filtersquad/rocket_pants/blob/master/lib/rocket_pants/errors.rb
  class ErrorRegistrar
    @@errors = {}

    # Returns a hash of all known errors, keyed by their error name.
    # @return [Hash{Symbol => ApeRawr::Error}] the hash of known errors.
    def self.all
      @@errors.dup
    end

    # Looks up a specific error from the given name, returning nil if none are found.
    # @param [#to_sym] name the name of the error to look up.
    # @return [Error, nil] the error class if found, otherwise nil.
    def self.[](name)
      @@errors[name.to_sym]
    end

    # Adds a given Error class in the list of all errors, making it suitable
    # for lookup via [].
    # @see Errors[]
    # @param [Error] error the error to register.
    def self.add(error)
      @@errors[error.error_name] = error
    end

    # Creates an error class to represent a given error state.
    # @param [Symbol] name the name of the given error
    # @param [Hash] options the options used to create the error class.
    # @option options [Symbol] :class_name the name of the class (under `ApeRawr`), defaulting to the classified name.
    # @option options [Symbol] :error_name the name of the error, defaulting to the name parameter.
    # @option options [Symbol] :http_status the status code for the given error, doing nothing if absent.
    # @example Adding a ApeRawr::NinjasUnavailable class w/ `:service_unavailable` as the status code:
    #   register! :ninjas_unavailable, :http_status => :service_unavailable
    def self.register!(name, options = {})
      klass_name = (options[:class_name] || name.to_s.classify).to_sym
      base_klass = options[:base] || Error
      raise ArgumentError, ":base must be a subclass of ApeRawr::Error" unless base_klass <= Error
      klass = Class.new(base_klass)
      klass.error_name(options[:error_name] || name.to_s.underscore)
      klass.http_status(options[:http_status]) if options[:http_status].present?
      (options[:under] || ApeRawr).const_set klass_name, klass
      add klass
      klass
    end

    # The default set of exceptions.
    register! :throttled,       :http_status => :service_unavailable
    register! :unauthenticated, :http_status => :unauthorized
    register! :invalid_version, :http_status => :not_found
    register! :not_implemented, :http_status => :service_unavailable
    register! :not_found,       :http_status => :not_found
    register! :bad_request,     :http_status => :bad_request
    register! :conflict,        :http_status => :conflict
    register! :forbidden,       :http_status => :forbidden
  end

  class InvalidResource < ApeRawr::Error
    http_status :unprocessable_entity
    error_name  :invalid_resource

    # Errors are ActiveModel Errors
    attr_reader :errors

    def initialize(errors, *args)
      @errors = errors
      super *args
    end

    def context
      super.tap do |ctx|
        extras            = (ctx[:metadata] ||= {})
        extras[:messages] = errors.to_hash if errors
      end
    end

    ErrorRegistrar.add self
  end
end
