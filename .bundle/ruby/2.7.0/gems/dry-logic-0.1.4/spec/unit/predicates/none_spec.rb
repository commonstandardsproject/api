require 'dry/logic/predicates'

RSpec.describe Dry::Logic::Predicates do
  describe '#none?' do
    let(:predicate_name) { :none? }

    context 'when value is nil' do
      let(:arguments_list) { [[nil]] }
      it_behaves_like 'a passing predicate'
    end

    context 'when value is not nil' do
      let(:arguments_list) do
        [
          [''],
          [true],
          [false],
          [0],
          [:symbol],
          [[]],
          [{}],
          [String]
        ]
      end
      it_behaves_like 'a failing predicate'
    end
  end
end
