module Dry
  module Logic
    def self.Result(input, value, rule)
      case value
      when Result
        value.class.new(value.input, value.success?, rule)
      when Array
        Result::Set.new(input, value, rule)
      else
        Result::Value.new(input, value, rule)
      end
    end

    class Result
      include Dry::Equalizer(:success?, :input, :rule)

      attr_reader :input, :value, :rule, :name

      class Result::Set < Result
        def success?
          value.all?(&:success?)
        end

        def to_ary
          indices = value.map { |v| v.failure? ? value.index(v) : nil }.compact
          [:input, [name, input, value.values_at(*indices).map(&:to_ary)]]
        end
      end

      class Result::Value < Result
        def to_ary
          [:input, [name, input, [rule.to_ary]]]
        end
        alias_method :to_a, :to_ary
      end

      class Result::LazyValue < Result
        def to_ary
          [:input, [rule.name, input, [rule.to_ary]]]
        end
        alias_method :to_a, :to_ary

        def input
          success? ? rule.evaluate_input(@input) : @input
        end
      end

      class Result::Wrapped < Result::Value
        def to_ary
          [:input, [rule.name, rule.evaluate_input(input), [rule.to_ary]]]
        end
        alias_method :to_a, :to_ary

        def wrapped?
          true
        end
      end

      class Result::Verified < Result
        attr_reader :predicate_id

        def initialize(result, predicate_id)
          @input = result.input
          @value = result.value
          @rule = result.rule
          @name = result.name
          @predicate_id = predicate_id
        end

        def call(*)
          Logic.Result(input, success?, rule)
        end

        def to_ary
          [:input, [name, input, [rule.to_ary]]]
        end
        alias_method :to_a, :to_ary

        def success?
          rule.predicate_id == predicate_id
        end
      end

      def initialize(input, value, rule)
        @input = input
        @value = value
        @rule = rule
        @name = rule.name
      end

      def call(*)
        self
      end

      def curry(predicate_id = nil)
        if predicate_id
          Result::Verified.new(self, predicate_id)
        else
          self
        end
      end

      def negated
        self.class.new(input, !value, rule)
      end

      def then(other)
        if success?
          other.(input)
        else
          Logic.Result(input, true, rule)
        end
      end

      def and(other)
        if success?
          other.(input)
        else
          self
        end
      end

      def or(other)
        if success?
          self
        else
          other.(input)
        end
      end

      def xor(other)
        other_result = other.(input)
        value = success? ^ other_result.success?

        if other_result.wrapped?
          Result::Wrapped.new(input, value, rule)
        else
          Logic.Result(other_result.input, value, rule)
        end
      end

      def success?
        @value
      end

      def failure?
        ! success?
      end

      def wrapped?
        false
      end
    end
  end
end
