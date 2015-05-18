# The part that activates bundler in your app
require 'bundler/setup'
require_relative './asn_standard_set_generator'
require 'oj'

Oj.default_options = {
  indent:      2,
  symbol_keys: false
}

ARGV.each do |a|
  ASNStandardSetQueryGenerator.generate(a)
end
