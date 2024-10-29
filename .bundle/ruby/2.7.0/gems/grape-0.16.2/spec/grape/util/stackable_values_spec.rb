require 'spec_helper'
module Grape
  module Util
    describe StackableValues do
      let(:parent) { StackableValues.new }
      subject { StackableValues.new(parent) }

      describe '#keys' do
        it 'returns all key' do
          subject[:some_thing] = :foo_bar
          subject[:some_thing_else] = :foo_bar
          expect(subject.keys).to eq [:some_thing, :some_thing_else].sort
        end

        it 'returns merged keys with parent' do
          parent[:some_thing] = :foo
          parent[:some_thing_else] = :foo

          subject[:some_thing] = :foo_bar
          subject[:some_thing_more] = :foo_bar

          expect(subject.keys).to eq [:some_thing, :some_thing_else, :some_thing_more].sort
        end
      end

      describe '#delete' do
        it 'deletes a key' do
          subject[:some_thing] = :new_foo_bar
          subject.delete :some_thing
          expect(subject[:some_thing]).to eq []
        end

        it 'does not delete parent values' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :new_foo_bar
          subject.delete :some_thing
          expect(subject[:some_thing]).to eq [:foo]
        end
      end

      describe '#[]' do
        it 'returns an array of values' do
          subject[:some_thing] = :foo
          expect(subject[:some_thing]).to eq [:foo]
        end

        it 'returns parent value when no value is set' do
          parent[:some_thing] = :foo
          expect(subject[:some_thing]).to eq [:foo]
        end

        it 'combines parent and actual values' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :foo_bar
          expect(subject[:some_thing]).to eq [:foo, :foo_bar]
        end

        it 'parent values are not changed' do
          parent[:some_thing] = :foo
          subject[:some_thing] = :foo_bar
          expect(parent[:some_thing]).to eq [:foo]
        end
      end

      describe '#[]=' do
        it 'sets a value' do
          subject[:some_thing] = :foo
          expect(subject[:some_thing]).to eq [:foo]
        end

        it 'pushes further values' do
          subject[:some_thing] = :foo
          subject[:some_thing] = :bar
          expect(subject[:some_thing]).to eq [:foo, :bar]
        end

        it 'can handle array values' do
          subject[:some_thing] = :foo
          subject[:some_thing] = [:bar, :more]
          expect(subject[:some_thing]).to eq [:foo, [:bar, :more]]

          parent[:some_thing_else] = [:foo, :bar]
          subject[:some_thing_else] = [:some, :bar, :foo]

          expect(subject[:some_thing_else]).to eq [[:foo, :bar], [:some, :bar, :foo]]
        end
      end

      describe '#to_hash' do
        it 'returns a Hash representation' do
          parent[:some_thing] = :foo
          subject[:some_thing] = [:bar, :more]
          subject[:some_thing_more] = :foo_bar
          expect(subject.to_hash).to eq(some_thing: [:foo, [:bar, :more]], some_thing_more: [:foo_bar])
        end
      end

      describe '#clone' do
        let(:obj_cloned) { subject.clone }
        it 'copies all values' do
          parent = StackableValues.new
          child = StackableValues.new parent
          grandchild = StackableValues.new child

          parent[:some_thing] = :foo
          child[:some_thing] = [:bar, :more]
          grandchild[:some_thing] = :grand_foo_bar
          grandchild[:some_thing_more] = :foo_bar

          expect(grandchild.clone.to_hash).to eq(some_thing: [:foo, [:bar, :more], :grand_foo_bar], some_thing_more: [:foo_bar])
        end

        context 'complex (i.e. not primitive) data types (ex. middleware, please see bug #930)' do
          let(:middleware) { double }

          before { subject[:middleware] = middleware }

          it 'copies values; does not duplicate them' do
            expect(obj_cloned[:middleware]).to eq [middleware]
          end
        end
      end
    end
  end
end
