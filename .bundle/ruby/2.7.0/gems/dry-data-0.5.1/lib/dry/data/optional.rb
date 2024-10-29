require 'dry/data/decorator'

module Dry
  module Data
    class Optional
      include Decorator
      include TypeBuilder

      def call(input)
        Maybe(type[input])
      end
      alias_method :[], :call
    end
  end
end
