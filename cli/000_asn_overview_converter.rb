# The part that activates bundler in your app
require 'bundler/setup'
require 'oj'
require 'pp'
require 'typhoeus'
require_relative '../src/source_to_subject_mapping'
require_relative '../src/transformers/asn_resource_parser'
require 'mongo'


logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger


Oj.default_options = {
  indent:      2,
  symbol_keys: false
}


docs = Oj.load(File.read('sources/asn_standards_documents.js'))

client        = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')
jurisdictions = client["jurisdictions"]
find_id       = lambda{ |title| jurisdictions.find({title: title}).to_a.first[:_id]}

new_docs = docs["documents"].map{|doc|
  {
    date_modified:   doc["data"]["date_modified"][0],
    date_valid:      doc["data"]["date_valid"][0],
    description:     doc["data"]["description"][0],
    id:              doc["id"].upcase,
    jurisdiction:    doc["data"]["jurisdiction"][0],
    jurisdiction_id: find_id.call(doc["data"]["jurisdiction"][0]),
    subject:         SOURCE_TO_SUBJECT_MAPPINGS[doc["data"]["title"][0]],
    title:           doc["data"]["title"][0],
    url:             doc["data"]["identifier"][0],
  }
}.map{|doc|
  doc[:url]
}

# p new_docs[0] + "_full.json"
# response = Typhoeus.get(new_docs[0] + "_full.json", followlocation: true)
# doc = ASNResourceParser.convert(Oj.load(response.body))
# client[:standards_documents].find({_id: doc["_id"]}).update_one(doc, {upsert: true})


taken = new_docs#[0..1]
hydra = Typhoeus::Hydra.new(max_concurrency: 20)

requests = taken.map{ |url|
  request = Typhoeus::Request.new(url + "_full.json", followlocation: true)
  hydra.queue(request)
  request
}


hydra.run


responses = requests.map.with_index{|request, index|
  p "#{index}. Converting: #{request.url}"
  doc = ASNResourceParser.convert(Oj.load(request.response.body))
  doc["retrieved"] = {
    from: request.url,
    at:   Time.now
  }
  begin
    p "IMPORTING #{doc["document"]["title"]}"
    client[:standards_documents].find({_id: doc["_id"]}).update_one(doc, {upsert: true})

    # We add the document to the jurisdiction so that we have can easily have a count
    # of how mnay documents a jurisdiction has
    client[:jurisdictions].find({_id: doc["document"]["jurisdictionId"]}).update({
      :$addToSet => {:cachedDocumentIds => doc["_id"]}
    })
  rescue Exception => e
    puts "EXCEPTION"
    puts e.message
    puts e.backtrace.inspect
    pp doc
  end
}
