# The part that activates bundler in your app
require 'bundler/setup'
require_relative '../src/transformers/asn_standard_set_query_generator'
require 'oj'
require 'pp'

Oj.default_options = {
  indent:      2,
  symbol_keys: false
}

require 'mongo'
logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')

# client[:standard_sets].find().limit(1).each{|set|
client[:standards_documents].find().each{|set|
  p "Converting a set #{set["document"]["title"]}"
  new_queries = ASNStandardSetQueryGenerator.generate(set)
  client[:standards_documents].find({_id: set["_id"]}).update_one({
    :$unset => {"standardSetQueries" => 1},
    :$set => {"standardsSetQueries" => new_queries}
  })
}
