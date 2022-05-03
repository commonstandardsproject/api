require 'spec_helper'

describe Grape::Validations::Types do
  module TypesSpec
    class FooType
      def self.parse(_)
      end
    end

    class BarType
      def self.parse
      end
    end
  end

  VirtusA = Virtus::Attribute.build(String)

  module VirtusModule
    include Virtus.module
  end

  class VirtusB
    include VirtusModule
  end

  class VirtusC
    include Virtus.model
  end

  MyAxiom = Axiom::Types::String.new do
    minimum_length 1
    maximum_length 30
  end

  describe '::primitive?' do
    [
      Integer, Float, Numeric, BigDecimal,
      Virtus::Attribute::Boolean, String, Symbol,
      Date, DateTime, Time, Rack::Multipart::UploadedFile
    ].each do |type|
      it "recognizes #{type} as a primitive" do
        expect(described_class.primitive?(type)).to be_truthy
      end
    end

    it 'identifies unknown types' do
      expect(described_class.primitive?(Object)).to be_falsy
      expect(described_class.primitive?(TypesSpec::FooType)).to be_falsy
    end
  end

  describe '::structure?' do
    [
      Hash, Array, Set
    ].each do |type|
      it "recognizes #{type} as a structure" do
        expect(described_class.structure?(type)).to be_truthy
      end
    end
  end

  describe '::recognized?' do
    [
      VirtusA, VirtusB, VirtusC, MyAxiom
    ].each do |type|
      it "recognizes #{type}" do
        expect(described_class.recognized?(type)).to be_truthy
      end
    end
  end

  describe '::special?' do
    [
      JSON, Array[JSON], File, Rack::Multipart::UploadedFile
    ].each do |type|
      it "provides special handling for #{type.inspect}" do
        expect(described_class.special?(type)).to be_truthy
      end
    end
  end

  describe '::custom?' do
    it 'returns false if the type does not respond to :parse' do
      expect(described_class.custom?(Object)).to be_falsy
    end

    it 'returns true if the type responds to :parse with one argument' do
      expect(described_class.custom?(TypesSpec::FooType)).to be_truthy
    end

    it 'returns false if the type\'s #parse method takes other than one argument' do
      expect(described_class.custom?(TypesSpec::BarType)).to be_falsy
    end
  end
end
