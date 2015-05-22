# The part that activates bundler in your app
require 'bundler/setup'
require_relative "../src/transformers/query_to_standard_set"

require 'oj'

Oj.default_options = {
  indent:      2,
  symbol_keys: false
}

ARGV.each do |id, index|
  client             = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')
  standards_document = client[:standards_documents].find({_id: id}).to_a.first
  QueryToStandardSet.generate(standards_document["standards"], standards_document["standardSetQueries"][1]["query"])
end
