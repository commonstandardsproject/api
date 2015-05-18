# The part that activates bundler in your app
require 'bundler/setup'
require 'oj'
require 'pp'
require 'mongo'

require_relative 'src/source_to_subject_mapping'

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
}

pp new_docs
