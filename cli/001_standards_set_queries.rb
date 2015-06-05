# The part that activates bundler in your app
require 'bundler/setup'
require_relative '../src/transformers/asn_standard_set_query_generator'
require 'oj'
require 'pp'
require 'mongo'


logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


# client[:standards_documents].find({_id: "D2529099:2013-12-17T17:33:08-05:00"}).each{|set|
$db[:standards_documents].find().each{|set|
  p "Converting a set #{set["document"]["title"]}"
  new_queries = ASNStandardSetQueryGenerator.generate(set)
  $db[:standards_documents].find({_id: set["_id"]}).update_one({
    :$set => {"standardsSetQueries" => new_queries}
  })
}
