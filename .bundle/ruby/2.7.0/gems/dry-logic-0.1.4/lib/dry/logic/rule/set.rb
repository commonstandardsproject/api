module Dry
  module Logic
    class Rule::Set < Rule
      def call(input)
        Logic.Result(input, predicate.map { |rule| rule.(input) }, self)
      end

      def type
        :set
      end

      def at(*args)
        self.class.new(name, predicate.values_at(*args))
      end

      def to_ary
        [type, [name, predicate.map(&:to_ary)]]
      end
      alias_method :to_a, :to_ary
    end
  end
end
