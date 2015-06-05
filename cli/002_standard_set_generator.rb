# The part that activates bundler in your app
require 'bundler/setup'
require_relative "../src/transformers/query_to_standard_set"
require_relative "../src/update_standards_set"

require 'mongo'
logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


$db[:standards_documents].find().each_with_index{|standards_document, index|
  p ""
  p ""
  p "===================================================="
  p "Number: #{index + 1}"
  p "Converting #{standards_document["document"]["title"]}"
  p "===================================================="
  standards_document["standardsSetQueries"].each{|query|
    p "Converting #{query["title"]}"
    set = QueryToStandardSet.generate(standards_document, query)
    UpdateStandardsSet.update(set)
  }
}
