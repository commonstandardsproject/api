require 'dry/logic/rule_compiler'

RSpec.describe Dry::Logic::RuleCompiler, '#call' do
  subject(:compiler) { RuleCompiler.new(predicates) }

  let(:predicates) {
    { key?: predicate,
      attr?: predicate,
      filled?: predicate,
      gt?: predicate,
      email: val_rule.('email').curry(:filled?),
      left: res_left_rule,
      right: double(input: 312) }
  }

  let(:predicate) { double(:predicate).as_null_object }

  let(:key_rule) { Rule::Key.new(:email, predicate) }
  let(:not_key_rule) { Rule::Key.new(:email, predicate).negation }
  let(:attr_rule) { Rule::Attr.new(:email, predicate) }
  let(:val_rule) { Rule::Value.new(:email, predicate) }
  let(:check_rule) { Rule::Check::Unary.new(:email, predicates[:email], [:email]) }
  let(:res_rule) { Rule::Result.new(:email, predicates[:email]) }
  let(:res_left_rule) { Rule::Result.new(:left, predicate) }
  let(:and_rule) { key_rule & val_rule }
  let(:or_rule) { key_rule | val_rule }
  let(:xor_rule) { key_rule ^ val_rule }
  let(:set_rule) { Rule::Set.new(:email, [val_rule]) }
  let(:each_rule) { Rule::Each.new(:email, val_rule) }

  it 'compiles key rules' do
    ast = [[:key, [:email, [:predicate, [:key?, predicate]]]]]

    rules = compiler.(ast)

    expect(rules).to eql([key_rule])
  end

  it 'compiles check rules' do
    ast = [[:check, [:email, [:predicate, [:email, [:filled?]]]]]]

    rules = compiler.(ast)

    expect(rules).to eql([check_rule])
  end

  it 'compiles result rules' do
    ast = [[:res, [:email, [:predicate, [:email, [:filled?]]]]]]

    rules = compiler.(ast)

    expect(rules).to eql([res_rule])
  end

  it 'compiles result rules with res args' do
    ast = [[:res, [:left, [:predicate, [:gt?, [:args, [[:res_arg, :right]]]]]]]]

    expect(predicate).to receive(:curry).with(312)

    rules = compiler.(ast)

    expect(rules).to eql([res_left_rule])
  end

  it 'compiles attr rules' do
    ast = [[:attr, [:email, [:predicate, [:attr?, predicate]]]]]

    rules = compiler.(ast)

    expect(rules).to eql([attr_rule])
  end

  it 'compiles negated rules' do
    ast = [[:not, [:key, [:email, [:predicate, [:key?, predicate]]]]]]

    rules = compiler.(ast)

    expect(rules).to eql([not_key_rule])
  end

  it 'compiles conjunction rules' do
    ast = [
      [
        :and, [
          [:key, [:email, [:predicate, [:key?, []]]]],
          [:val, [:email, [:predicate, [:filled?, []]]]]
        ]
      ]
    ]

    rules = compiler.(ast)

    expect(rules).to eql([and_rule])
  end

  it 'compiles disjunction rules' do
    ast = [
      [
        :or, [
          [:key, [:email, [:predicate, [:key?, []]]]],
          [:val, [:email, [:predicate, [:filled?, []]]]]
        ]
      ]
    ]

    rules = compiler.(ast)

    expect(rules).to eql([or_rule])
  end

  it 'compiles exclusive disjunction rules' do
    ast = [
      [
        :xor, [
          [:key, [:email, [:predicate, [:key?, []]]]],
          [:val, [:email, [:predicate, [:filled?, []]]]]
        ]
      ]
    ]

    rules = compiler.(ast)

    expect(rules).to eql([xor_rule])
  end

  it 'compiles set rules' do
    ast = [
      [
        :set, [
          :email, [
            [:val, [:email, [:predicate, [:filled?, []]]]]
          ]
        ]
      ]
    ]

    rules = compiler.(ast)

    expect(rules).to eql([set_rule])
  end

  it 'compiles each rules' do
    ast = [
      [
        :each, [
          :email, [:val, [:email, [:predicate, [:filled?, []]]]]
        ]
      ]
    ]

    rules = compiler.(ast)

    expect(rules).to eql([each_rule])
  end
end
