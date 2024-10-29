require 'dry/data/decorator'

module Dry
  module Data
    class Enum
      include Decorator

      attr_reader :values

      def initialize(type, options)
        super
        @values = options.fetch(:values).freeze
        @values.each(&:freeze)
      end

      def call(input)
        case input
        when Fixnum then type[values[input]]
        else type[input] end
      end
      alias_method :[], :call
    end
  end
end
