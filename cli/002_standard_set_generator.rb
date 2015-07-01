# The part that activates bundler in your app
require 'bundler/setup'
require_relative "../src/transformers/query_to_standard_set"
require_relative "../src/update_standards_set"
require 'parallel'
require 'mongo'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')

ids = $db[:standards_documents].find().projection(:_id => 1).to_a.map{|hash| hash[:_id]}

Parallel.each_with_index(ids, :in_processes => 16){ |id, index|

  $db[:standards_documents].find(:_id => id).each{|standards_document|
    p ""
    p ""
    p "===================================================="
    p "Number: #{index + 1}"
    p "Converting #{standards_document["document"]["title"]}"
    p "===================================================="
    # begin
    Parallel.each(standards_document["standardsSetQueries"], :in_processes => 16){|query|
      p "Converting #{query["title"]}"
      set = QueryToStandardSet.generate(standards_document, query)
      UpdateStandardsSet.update(set)
      begin
        raise Parallel::Kill
      rescue Exception => e
        p e
      end
    }
  }
}
