# The part that activates bundler in your app
require 'bundler/setup'
require_relative '../src/source_to_subject_mapping'
require 'mongo'
require 'oj'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')



# $db[:standards_documents].find({_id: "D1000284:2013-06-16T17:25:35-04:00"}).each{|standards_document|
# $db[:standards_documents].find().each_with_index{|standards_document, index|
#   p "#{index}: Converting: #{standards_document["document"]["title"]}"
#   $db[:standards_documents].find({_id: standards_document["_id"]}).update_one({
#     :$set => {"document.subject" => SOURCE_TO_SUBJECT_MAPPINGS[standards_document["document"]["title"]]}
#   })
# }


# $db[:new_standard_sets].find({_id: "5A99211C6D874994A2CFEE2AE40023DD_D2384125_grade-pre-k"}).each_with_index{|standard_set, index|
$db[:new_standard_sets].find().each_with_index{|standard_set, index|
  p "#{index}: Converting: #{standard_set["_id"]}"
  document = $db[:standards_documents].find({_id: standard_set["documentId"]}).to_a.first
  $db[:new_standard_sets].find({_id: standard_set["_id"]}).update_one({
    :$set => {
      "subject"       => document["document"]["subject"],
      "documentTitle" => document["document"]["title"],
      "sourceURL"     => document["document"]["source"],
    }
  })
}
