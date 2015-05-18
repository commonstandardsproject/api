# The part that activates bundler in your app
require 'bundler/setup'
require_relative './resource_converter'
require_relative './asn_converter'
require 'oj'

Oj.default_options = {
  indent:      2,
  symbol_keys: false
}

ARGV.each do |a|
  ASNConverter.convert(a)
end
