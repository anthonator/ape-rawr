module ApeRawr
  module Validations
    ##
    # All validators must inherit from this class.
    #
    class Validator
      include ApeRawr::ErrorHandler

      attr_reader :attrs

      def initialize(attrs, options, required, scope)
        @attrs = Array(attrs)
        @required = required
        @scope = scope

        if options.is_a?(Hash) && !options.empty?
          error!(:unknown_options, :options => options)
        end
      end

      def validate!(params)
        attributes = AttributesIterator.new(self, @scope, params)
        attributes.each do |resource_params, attr_name|
          if @required || resource_params.has_key?(attr_name)
            validate_param!(attr_name, resource_params)
          end
        end
      end

      class AttributesIterator
        include Enumerable

        def initialize(validator, scope, params)
          @attrs = validator.attrs
          @params = scope.params(params)
          @params = (@params.is_a?(Array) ? @params : [@params])
        end

        def each
          @params.each do |resource_params|
            @attrs.each do |attr_name|
              yield resource_params, attr_name
            end
          end
        end
      end

      private
      def self.convert_to_short_name(klass)
        ret = klass.name.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
        File.basename(ret, '_validator')
      end
    end

    ##
    # Base class for all validators taking only one param.
    class SingleOptionValidator < Validator
      def initialize(attrs, options, required, scope)
        @option = options
        super
      end

    end

    # We define Validator::inherited here so SingleOptionValidator
    # will not be considered a validator.
    class Validator
      def self.inherited(klass)
        short_name = convert_to_short_name(klass)
        Validations::register_validator(short_name, klass)
      end
    end

    class << self
      attr_accessor :validators
    end

    self.validators = {}

    def self.register_validator(short_name, klass)
      validators[short_name] = klass
    end

    class ParamsScope
      attr_accessor :element, :parent, :api

      def initialize(api, params, element, parent, &block)
        @element = element
        @parent  = parent
        @api     = api
        @params = params
        @declared_params = []

        instance_eval(&block)

        configure_declared_params
      end

      def requires(*attrs)
        validations = {:presence => true}
        if attrs.last.is_a?(Hash)
          validations.merge!(attrs.pop)
        end

        push_declared_params(attrs)
        validates(attrs, validations)
      end

      def optional(*attrs)
        validations = {}
        if attrs.last.is_a?(Hash)
          validations.merge!(attrs.pop)
        end

        push_declared_params(attrs)
        validates(attrs, validations)
      end

      def group(element, &block)
        ParamsScope.new(@api, @params, element, self, &block)
      end

      def params(params)
        params = @parent.params(params) if @parent
        params = params[@element] || {} if @element
        params
      end

      def full_name(name)
        return "#{@parent.full_name(@element)}[#{name}]" if @parent
        name.to_s
      end

      protected
      def push_declared_params(attrs)
        @declared_params.concat attrs
      end

      private
      # Pushes declared params to parent or settings
      def configure_declared_params
        if @parent
          @parent.push_declared_params [element => @declared_params]
        else
          @api.settings.peek[:declared_params] ||= []
          @api.settings[:declared_params].concat @declared_params
        end
      end

      def validates(attrs, validations)
        doc_attrs = { :required => validations.keys.include?(:presence) }

        # special case (type = coerce)
        if validations[:type]
          validations[:coerce] = validations.delete(:type)
        end

        if coerce_type = validations[:coerce]
          doc_attrs[:type] = coerce_type.to_s
        end

        if desc = validations.delete(:desc)
          doc_attrs[:desc] = desc
        end

        if default = validations[:default]
          doc_attrs[:default] = default
        end

        full_attrs = attrs.collect{ |name| { :name => name, :full_name => full_name(name)} }
        @api.document_attribute(full_attrs, doc_attrs)

        # Validate for presence before any other validators
        if validations.has_key?(:presence) && validations[:presence]
          validate('presence', validations[:presence], attrs, doc_attrs)
        end

        # Before we run the rest of the validators, lets handle
        # whatever coercion so that we are working with correctly
        # type casted values
        if validations.has_key? :coerce
          validate('coerce', validations[:coerce], attrs, doc_attrs)
          validations.delete(:coerce)
        end

        validations.each do |type, options|
          validate(type, options, attrs, doc_attrs)
        end
      end

      def validate(type, options, attrs, doc_attrs)
        validator_class = Validations::validators[type.to_s]

        if validator_class
          validator_class.new(attrs, options, doc_attrs[:required], self).validate!(@params)
        else
          error!(:unknown_validator, :options => options)
        end
      end
    end

    module ClassMethods
      def settings
        @settings ||= ApeRawr::Util::HashStack.new
      end

      def reset_validations!
        settings.peek[:declared_params] = []
        settings.peek[:validations] = []
      end

      def params(action = :all, &block)
        base = self
        action = action.to_s
        before_filter do
          if action == 'all' || params[:action] == action
            ParamsScope.new(base, params, nil, nil, &block)
          end
        end
      end

      def document_attribute(names, opts)
        @last_description ||= {}
        @last_description[:params] ||= {}
        Array(names).each do |name|
          @last_description[:params][name[:full_name].to_s] ||= {}
          @last_description[:params][name[:full_name].to_s].merge!(opts)
        end
      end
    end
  end
end

# Load all defined validations.
Dir[File.expand_path('../validations/*.rb', __FILE__)].each do |path|
  require(path)
end
