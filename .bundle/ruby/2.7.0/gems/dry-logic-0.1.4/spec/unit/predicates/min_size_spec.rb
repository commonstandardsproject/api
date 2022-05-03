require 'dry/logic/predicates'

RSpec.describe Dry::Logic::Predicates do
  describe '#min_size?' do
    let(:predicate_name) { :min_size? }

    context 'when value size is greater than n' do
      let(:arguments_list) do
        [
          [1, [1, 2]],
          [3, 'Jill'],
          [1, { 1 => 'st', 2 => 'nd' }],
          [7, 1],
          [4, 1..5]
        ]
      end

      it_behaves_like 'a passing predicate'
    end

    context 'when value size is equal to n' do
      let(:arguments_list) do
        [
          [2, [1, 2]],
          [4, 'Jill'],
          [2, { 1 => 'st', 2 => 'nd' }],
          [8, 1],
          [5, 1..5]
        ]
      end

      it_behaves_like 'a passing predicate'
    end

    context 'with value size is less than n' do
      let(:arguments_list) do
        [
          [3, [1, 2]],
          [5, 'Jill'],
          [3, { 1 => 'st', 2 => 'nd' }],
          [9, 1],
          [6, 1..5]
        ]
      end

      it_behaves_like 'a failing predicate'
    end
  end
end
