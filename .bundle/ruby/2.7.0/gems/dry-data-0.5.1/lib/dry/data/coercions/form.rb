require 'date'
require 'bigdecimal'
require 'bigdecimal/util'

module Dry
  module Data
    module Coercions
      module Form
        TRUE_VALUES = %w[1 on  t true  y yes].freeze
        FALSE_VALUES = %w[0 off f false n no].freeze
        BOOLEAN_MAP = Hash[TRUE_VALUES.product([true]) + FALSE_VALUES.product([false])].freeze

        def self.to_nil(input)
          if input.is_a?(String) && input == ''
            nil
          else
            input
          end
        end

        def self.to_date(input)
          Date.parse(input)
        rescue ArgumentError
          input
        end

        def self.to_date_time(input)
          DateTime.parse(input)
        rescue ArgumentError
          input
        end

        def self.to_time(input)
          Time.parse(input)
        rescue ArgumentError
          input
        end

        def self.to_true(input)
          BOOLEAN_MAP.fetch(input, input)
        end

        def self.to_false(input)
          BOOLEAN_MAP.fetch(input, input)
        end

        def self.to_int(input)
          if input == ''
            nil
          else
            result = input.to_i

            if result === 0 && input != '0'
              input
            else
              result
            end
          end
        end

        def self.to_float(input)
          if input == ''
            nil
          else
            result = input.to_f

            if result == 0.0 && (input != '0' || input != '0.0')
              input
            else
              result
            end
          end
        end

        def self.to_decimal(input)
          if input == ''
            nil
          else
            result = to_float(input)

            if result.is_a?(Float)
              result.to_d
            else
              result
            end
          end
        end
      end
    end
  end
end
