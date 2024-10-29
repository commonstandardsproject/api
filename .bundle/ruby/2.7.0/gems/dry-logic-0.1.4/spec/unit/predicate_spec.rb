require 'dry/logic/predicate'

RSpec.describe Dry::Logic::Predicate do
  describe '#call' do
    it 'returns result of the predicate function' do
      is_empty = Dry::Logic::Predicate.new(:is_empty) { |str| str.empty? }

      expect(is_empty.('')).to be(true)

      expect(is_empty.('filled')).to be(false)
    end
  end

  describe '#curry' do
    it 'returns curried predicate' do
      min_age = Dry::Logic::Predicate.new(:min_age) { |age, input| input >= age }

      min_age_18 = min_age.curry(18)

      expect(min_age_18.args).to eql([18])

      expect(min_age_18.(18)).to be(true)
      expect(min_age_18.(19)).to be(true)
      expect(min_age_18.(17)).to be(false)
    end
  end
end
