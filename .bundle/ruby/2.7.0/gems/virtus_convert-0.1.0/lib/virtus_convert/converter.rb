require 'virtus_convert/object'
require 'virtus_convert/hash'
require 'virtus_convert/array'

module VirtusConvert

  class Converter

    def initialize(unknown, options = {})
      @root = VirtusConvert::Hash.new(unknown, options) if unknown.is_a? ::Hash
      @root ||= VirtusConvert::Array.new(unknown, options) if unknown.is_a? ::Array
      @root ||= VirtusConvert::Object.new(unknown, options)
    end

    def to_hash
      @root.respond_to?(:to_hash) ? @root.to_hash : @root
    end

  end

end
