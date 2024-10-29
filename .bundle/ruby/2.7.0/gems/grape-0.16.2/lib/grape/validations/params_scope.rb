module Grape
  module Validations
    class ParamsScope
      attr_accessor :element, :parent, :index

      include Grape::DSL::Parameters

      # Open up a new ParamsScope, allowing parameter definitions per
      #   Grape::DSL::Params.
      # @param opts [Hash] options for this scope
      # @option opts :element [Symbol] the element that contains this scope; for
      #   this to be relevant, @parent must be set
      # @option opts :parent [ParamsScope] the scope containing this scope
      # @option opts :api [API] the API endpoint to modify
      # @option opts :optional [Boolean] whether or not this scope needs to have
      #   any parameters set or not
      # @option opts :type [Class] a type meant to govern this scope (deprecated)
      # @option opts :dependent_on [Symbol] if present, this scope should only
      #   validate if this param is present in the parent scope
      # @yield the instance context, open for parameter definitions
      def initialize(opts, &block)
        @element      = opts[:element]
        @parent       = opts[:parent]
        @api          = opts[:api]
        @optional     = opts[:optional] || false
        @type         = opts[:type]
        @dependent_on = opts[:dependent_on]
        @declared_params = []

        instance_eval(&block) if block_given?

        configure_declared_params
      end

      # @return [Boolean] whether or not this entire scope needs to be
      #   validated
      def should_validate?(parameters)
        return false if @optional && params(parameters).respond_to?(:all?) && params(parameters).all?(&:blank?)
        @dependent_on.each do |dependency|
          return false if params(parameters).try(:[], dependency).blank?
        end if @dependent_on
        return true if parent.nil?
        parent.should_validate?(parameters)
      end

      # @return [String] the proper attribute name, with nesting considered.
      def full_name(name)
        case
        when nested?
          # Find our containing element's name, and append ours.
          "#{@parent.full_name(@element)}#{parent_index}[#{name}]"
        when lateral?
          # Find the name of the element as if it was at the
          # same nesting level as our parent.
          @parent.full_name(name)
        else
          # We must be the root scope, so no prefix needed.
          name.to_s
        end
      end

      def parent_index
        "[#{@parent.index}]" if @parent.present? && @parent.index.present?
      end

      # @return [Boolean] whether or not this scope is the root-level scope
      def root?
        !@parent
      end

      # A nested scope is contained in one of its parent's elements.
      # @return [Boolean] whether or not this scope is nested
      def nested?
        @parent && @element
      end

      # A lateral scope is subordinate to its parent, but its keys are at the
      # same level as its parent and thus is not contained within an element.
      # @return [Boolean] whether or not this scope is lateral
      def lateral?
        @parent && !@element
      end

      # @return [Boolean] whether or not this scope needs to be present, or can
      #   be blank
      def required?
        !@optional
      end

      protected

      # Adds a parameter declaration to our list of validations.
      # @param attrs [Array] (see Grape::DSL::Parameters#requires)
      def push_declared_params(attrs)
        if lateral?
          @parent.push_declared_params(attrs)
        else
          @declared_params.concat attrs
        end
      end

      private

      def require_required_and_optional_fields(context, opts)
        if context == :all
          optional_fields = Array(opts[:except])
          required_fields = opts[:using].keys - optional_fields
        else # context == :none
          required_fields = Array(opts[:except])
          optional_fields = opts[:using].keys - required_fields
        end
        required_fields.each do |field|
          field_opts = opts[:using][field]
          fail ArgumentError, "required field not exist: #{field}" unless field_opts
          requires(field, field_opts)
        end
        optional_fields.each do |field|
          field_opts = opts[:using][field]
          optional(field, field_opts) if field_opts
        end
      end

      def require_optional_fields(context, opts)
        optional_fields = opts[:using].keys
        optional_fields -= Array(opts[:except]) unless context == :all
        optional_fields.each do |field|
          field_opts = opts[:using][field]
          optional(field, field_opts) if field_opts
        end
      end

      def validate_attributes(attrs, opts, &block)
        validations = opts.clone
        validations[:type] ||= Array if block
        validates(attrs, validations)
      end

      # Returns a new parameter scope, subordinate to the current one and nested
      # under the parameter corresponding to `attrs.first`.
      # @param attrs [Array] the attributes passed to the `requires` or
      #   `optional` invocation that opened this scope.
      # @param optional [Boolean] whether the parameter this are nested under
      #   is optional or not (and hence, whether this block's params will be).
      # @yield parameter scope
      def new_scope(attrs, optional = false, &block)
        # if required params are grouped and no type or unsupported type is provided, raise an error
        type = attrs[1] ? attrs[1][:type] : nil
        if attrs.first && !optional
          fail Grape::Exceptions::MissingGroupTypeError.new if type.nil?
          fail Grape::Exceptions::UnsupportedGroupTypeError.new unless Grape::Validations::Types.group?(type)
        end

        opts = attrs[1] || { type: Array }

        self.class.new(
          api:      @api,
          element:  attrs.first,
          parent:   self,
          optional: optional,
          type:     opts[:type],
          &block)
      end

      # Returns a new parameter scope, not nested under any current-level param
      # but instead at the same level as the current scope.
      # @param options [Hash] options to control how this new scope behaves
      # @option options :dependent_on [Symbol] if given, specifies that this
      #   scope should only validate if this parameter from the above scope is
      #   present
      # @yield parameter scope
      def new_lateral_scope(options, &block)
        self.class.new(
          api:          @api,
          element:      nil,
          parent:       self,
          options:      @optional,
          type:         Hash,
          dependent_on: options[:dependent_on],
          &block)
      end

      # Pushes declared params to parent or settings
      def configure_declared_params
        if nested?
          @parent.push_declared_params [element => @declared_params]
        else
          @api.namespace_stackable(:declared_params, @declared_params)

          @api.route_setting(:declared_params, []) unless @api.route_setting(:declared_params)
          @api.route_setting(:declared_params).concat @declared_params
        end
      end

      def validates(attrs, validations)
        doc_attrs = { required: validations.keys.include?(:presence) }

        coerce_type = infer_coercion(validations)

        doc_attrs[:type] = coerce_type.to_s if coerce_type

        desc = validations.delete(:desc) || validations.delete(:description)
        doc_attrs[:desc] = desc if desc

        default = validations[:default]
        doc_attrs[:default] = default if validations.key?(:default)

        values = (options_key?(:values, :value, validations)) ? validations[:values][:value] : validations[:values]
        doc_attrs[:values] = values if values

        coerce_type = guess_coerce_type(coerce_type, values)

        # default value should be present in values array, if both exist and are not procs
        check_incompatible_option_values(values, default)

        # type should be compatible with values array, if both exist
        validate_value_coercion(coerce_type, values)

        doc_attrs[:documentation] = validations.delete(:documentation) if validations.key?(:documentation)

        full_attrs = attrs.collect { |name| { name: name, full_name: full_name(name) } }
        @api.document_attribute(full_attrs, doc_attrs)

        # Validate for presence before any other validators
        if validations.key?(:presence) && validations[:presence]
          validate('presence', validations[:presence], attrs, doc_attrs)
          validations.delete(:presence)
          validations.delete(:message) if validations.key?(:message)
        end

        # Before we run the rest of the validators, let's handle
        # whatever coercion so that we are working with correctly
        # type casted values
        coerce_type validations, attrs, doc_attrs

        validations.each do |type, options|
          validate(type, options, attrs, doc_attrs)
        end
      end

      # Validate and comprehend the +:type+, +:types+, and +:coerce_with+
      # options that have been supplied to the parameter declaration.
      # The +:type+ and +:types+ options will be removed from the
      # validations list, replaced appropriately with +:coerce+ and
      # +:coerce_with+ options that will later be passed to
      # {Validators::CoerceValidator}. The type that is returned may be
      # used for documentation and further validation of parameter
      # options.
      #
      # @param validations [Hash] list of validations supplied to the
      #   parameter declaration
      # @return [class-like] type to which the parameter will be coerced
      # @raise [ArgumentError] if the given type options are invalid
      def infer_coercion(validations)
        if validations.key?(:type) && validations.key?(:types)
          fail ArgumentError, ':type may not be supplied with :types'
        end

        validations[:coerce] = (options_key?(:type, :value, validations) ? validations[:type][:value] : validations[:type]) if validations.key?(:type)
        validations[:coerce_message] = (options_key?(:type, :message, validations) ? validations[:type][:message] : nil) if validations.key?(:type)
        validations[:coerce] = (options_key?(:types, :value, validations) ? validations[:types][:value] : validations[:types]) if validations.key?(:types)
        validations[:coerce_message] = (options_key?(:types, :message, validations) ? validations[:types][:message] : nil) if validations.key?(:types)

        validations.delete(:types) if validations.key?(:types)

        coerce_type = validations[:coerce]

        # Special case - when the argument is a single type that is a
        # variant-type collection.
        if Types.multiple?(coerce_type) && validations.key?(:type)
          validations[:coerce] = Types::VariantCollectionCoercer.new(
            coerce_type,
            validations.delete(:coerce_with)
          )
        end
        validations.delete(:type)

        coerce_type
      end

      # Enforce correct usage of :coerce_with parameter.
      # We do not allow coercion without a type, nor with
      # +JSON+ as a type since this defines its own coercion
      # method.
      def check_coerce_with(validations)
        return unless validations.key?(:coerce_with)
        # type must be supplied for coerce_with..
        fail ArgumentError, 'must supply type for coerce_with' unless validations.key?(:coerce)

        # but not special JSON types, which
        # already imply coercion method
        return unless [JSON, Array[JSON]].include? validations[:coerce]
        fail ArgumentError, 'coerce_with disallowed for type: JSON'
      end

      # Add type coercion validation to this scope,
      # if any has been specified.
      # This validation has special handling since it is
      # composited from more than one +requires+/+optional+
      # parameter, and needs to be run before most other
      # validations.
      def coerce_type(validations, attrs, doc_attrs)
        check_coerce_with(validations)

        return unless validations.key?(:coerce)

        coerce_options = {
          type: validations[:coerce],
          method: validations[:coerce_with],
          message: validations[:coerce_message]
        }
        validate('coerce', coerce_options, attrs, doc_attrs)
        validations.delete(:coerce_with)
        validations.delete(:coerce)
        validations.delete(:coerce_message)
      end

      def guess_coerce_type(coerce_type, values)
        return coerce_type if !values || values.is_a?(Proc)
        return values.first.class if coerce_type == Array && (values.is_a?(Range) || !values.empty?)
        coerce_type
      end

      def check_incompatible_option_values(values, default)
        return unless values && default
        return if values.is_a?(Proc) || default.is_a?(Proc)
        return if values.include?(default) || (Array(default) - Array(values)).empty?
        fail Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :values, values)
      end

      def validate(type, options, attrs, doc_attrs)
        validator_class = Validations.validators[type.to_s]

        if validator_class
          value = validator_class.new(attrs, options, doc_attrs[:required], self)
          @api.namespace_stackable(:validations, value)
        else
          fail Grape::Exceptions::UnknownValidator.new(type)
        end
      end

      def validate_value_coercion(coerce_type, values)
        return unless coerce_type && values
        return if values.is_a?(Proc)
        coerce_type = coerce_type.first if coerce_type.is_a?(Array)
        value_types = values.is_a?(Range) ? [values.begin, values.end] : values
        if coerce_type == Virtus::Attribute::Boolean
          value_types = value_types.map { |type| Virtus::Attribute.build(type) }
        end
        return unless value_types.any? { |v| !v.is_a?(coerce_type) }
        fail Grape::Exceptions::IncompatibleOptionValues.new(:type, coerce_type, :values, values)
      end

      def extract_message_option(attrs)
        return nil unless attrs.is_a?(Array)
        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}
        (opts.key?(:message) && !opts[:message].nil?) ? opts.delete(:message) : nil
      end

      def options_key?(type, key, validations)
        validations[type].respond_to?(:key?) && validations[type].key?(key) && !validations[type][key].nil?
      end
    end
  end
end
