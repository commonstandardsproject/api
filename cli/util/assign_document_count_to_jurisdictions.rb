# The part that activates bundler in your app
require 'bundler/setup'
require_relative "../src/transformers/query_to_standard_set"
require_relative "../src/update_standard_set"
require 'oj'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


Oj.default_options = {
  indent:      2,
  symbol_keys: false
}


$db[:standards_documents].find().each{|standards_document|
  $db[:jurisdictions].find({_id: standards_document["document"]["jurisdictionId"]}).update_one({
    :$addToSet => {:cachedDocumentIds => standards_document["_id"]}
  })
}
