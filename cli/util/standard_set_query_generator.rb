# The part that activates bundler in your app
require 'bundler/setup'
require_relative "../src/transformers/asn_standard_set_query_generator"

require 'oj'

Oj.default_options = {
  indent:      2,
  symbol_keys: false
}

ARGV.each do |path|
  hash = Oj.load(File.read(path))
  ASNStandardSetQueryGenerator.generate(hash)
end
