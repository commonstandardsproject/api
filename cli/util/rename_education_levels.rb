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

# client[:standards_documents].find({_id: "D2479054:2013-06-18T21:39:12-04:00"}).each{|set|
# client[:standards_documents].find().each{|set|
#   p "Converting a set #{set["document"]["title"]}"
#
#   new_standards = set["standards"].each{|key, standard|
#     levels = standard.delete "educationLevel"
#     standard["educationLevels"] = levels
#   }
#
#   client[:standards_documents].find({_id: set["_id"]}).update_one({
#     :$rename => {"document.educationLevel" => "document.educationLevels"},
#     :$set => {"standards" => new_standards}
#   })
# }
