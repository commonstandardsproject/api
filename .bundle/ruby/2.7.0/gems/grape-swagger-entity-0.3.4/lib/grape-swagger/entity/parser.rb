module GrapeSwagger
  module Entity
    class Parser
      attr_reader :model
      attr_reader :endpoint
      attr_reader :attribute_parser

      def initialize(model, endpoint)
        @model = model
        @endpoint = endpoint
        @attribute_parser = AttributeParser.new(endpoint)
      end

      def call
        parse_grape_entity_params(extract_params(model))
      end

      private

      class Alias
        attr_reader :original, :renamed
        def initialize(original, renamed)
          @original = original
          @renamed = renamed
        end
      end

      def extract_params(exposure)
        exposure.root_exposures.each_with_object({}) do |value, memo|
          if value.for_merge && (value.respond_to?(:entity_class) || value.respond_to?(:using_class_name))
            entity_class = value.respond_to?(:entity_class) ? value.entity_class : value.using_class_name

            extracted_params = extract_params(entity_class)
            memo.merge!(extracted_params)
          else
            opts = value.send(:options)
            opts[:as] ? memo[Alias.new(value.attribute, opts[:as])] = opts : memo[value.attribute] = opts
          end
        end
      end

      def parse_grape_entity_params(params, parent_model = nil)
        return unless params

        parsed = params.each_with_object({}) do |(entity_name, entity_options), memo|
          documentation_options = entity_options.fetch(:documentation, {})
          in_option = documentation_options.fetch(:in, nil).to_s
          hidden_option = documentation_options.fetch(:hidden, nil)
          next if in_option == 'header' || hidden_option == true

          entity_name = entity_name.original if entity_name.is_a?(Alias)
          final_entity_name = entity_options.fetch(:as, entity_name)
          documentation = entity_options[:documentation]

          memo[final_entity_name] = if entity_options[:nesting]
                                      parse_nested(entity_name, entity_options, parent_model)
                                    else
                                      attribute_parser.call(entity_options)
                                    end

          next unless documentation

          memo[final_entity_name][:readOnly] = documentation[:read_only].to_s == 'true' if documentation[:read_only]
          memo[final_entity_name][:description] = documentation[:desc] if documentation[:desc]
        end

        [parsed, required_params(params)]
      end

      def parse_nested(entity_name, entity_options, parent_model = nil)
        nested_entity = if parent_model.nil?
                          model.root_exposures.find_by(entity_name)
                        else
                          parent_model.nested_exposures.find_by(entity_name)
                        end

        params = nested_entity.nested_exposures.each_with_object({}) do |value, memo|
          memo[value.attribute] = value.send(:options)
        end

        properties, required = parse_grape_entity_params(params, nested_entity)
        is_a_collection = entity_options[:documentation].is_a?(Hash) &&
                          entity_options[:documentation][:type].to_s.casecmp('array').zero?

        if is_a_collection
          {
            type: :array,
            items: with_required({
              type: :object,
              properties: properties
            }, required)
          }
        else
          with_required({
            type: :object,
            properties: properties
          }, required)
        end
      end

      def required_params(params)
        params.select { |_, options| options.fetch(:documentation, {}).fetch(:required, false) }
              .map { |(key, options)| [options.fetch(:as, key), options] }
              .map(&:first)
      end

      def with_required(hash, required)
        return hash if required.empty?

        hash[:required] = required
        hash
      end
    end
  end
end
