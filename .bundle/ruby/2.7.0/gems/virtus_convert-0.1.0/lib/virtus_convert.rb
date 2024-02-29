require "virtus_convert/version"
require 'virtus_convert/converter'

module VirtusConvert
  def self.new(unknown, options={})
    VirtusConvert::Converter.new(unknown, options)
  end
end
