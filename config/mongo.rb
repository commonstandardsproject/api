require 'mongo'
require_relative "../importer/matchers/jurisdiction_matchers"
require_relative "../importer/matchers/source_to_subject_mapping"
# require_relative "../source_to_subject_mapping"

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
connection_string = ENV["MONGODB_CONNECTION_STRING"] || [ '127.0.0.1:27017' ]
$db = $db || Mongo::Client.new(connection_string, :database => 'common-standards-project')


# strings = []
# strings.push("SOURCE_TO_SUBJECT_MAPPINGS_GROUPED = {")
# $db[:standard_documents].find.projection({
#   "document" => 1
# }).to_a
# .sort_by{|d| d["document"]["jurisdictionTitle"]}.
# compact
# .group_by{|d|
#   d["document"]["jurisdictionTitle"]
# }.each{|title, docs|
#   strings.push("  # ===================")
#   strings.push("  # #{title}")
#   strings.push("  # ===================")
#   strings.push("  \"#{title}\" => {")
#   docs.sort_by{|doc|
#     doc["document"]["title"]
#   }.each{|doc|
#     # jurisdictionTitle = doc["document"]["jurisdictionTitle"]
#     documentTitle = doc["document"]["title"]
#     subject       = SOURCE_TO_SUBJECT_MAPPINGS[documentTitle]
#     title         = doc["document"]["title"]
#     spacing       = 66 - title.length
#     if spacing < 0
#       spacing = 1
#     end
#
#
#
#     strings.push("    \"#{title}\" #{" "*spacing}=> \"#{subject}\", # #{doc["document"]["valid"]}  #{doc["document"]["source"]}")
#   }
#   strings.push("  },")
# }
#
# strings.push("}")
# path = File.join(__dir__, "..", "importer", "matchers", "source_to_subject_mapping_grouped.rb")
# IO.write(path, strings.join("\n"))
