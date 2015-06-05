# The part that activates bundler in your app
require 'bundler/setup'
require_relative '../src/transformers/asn_resource_parser'
require 'oj'

Oj.default_options = {
  indent:      2,
  symbol_keys: false
}

ARGV.each do |a|
  hash = Oj.load(File.read(a))
  ASNResourceParser.convert(hash)
end
