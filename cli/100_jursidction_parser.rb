require 'bundler/setup'
require 'oj'
require 'pp'
require 'mongo'
require 'securerandom'
Mongo::Logger.logger.level = Logger::WARN

docs = Oj.load(File.read('sources/jurisdictions.json'))
client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


jurisdictions = docs["rdf:RDF"]["skos:Concept"].map{|el|
  title        = [el["skos:prefLabel"]].flatten.first["#text"]
  abbreviation = [el["skos:altLabel"] || {}].flatten.first["#text"]
  {
    url:          el["-rdf:about"],
    title:        title.gsub("\n", ''),
    abbreviation: abbreviation
  }
}.map{|hash|
  doc = client[:jurisdictions].find({:title => hash[:title]}).to_a.first
  if doc.nil?
    hash.merge!({
      :_id => SecureRandom.uuid().gsub('-', '').upcase,
    })
    client[:jurisdictions].insert_one(hash)
  end
  hash
}.map{|hash|
  doc = client[:jurisdictions].find({:title => hash[:title]}).find_one_and_update(
    :$set => {
      asnUrl:       hash[:url],
      abbreviation: hash[:abbreviation]
    }
  ) || {}
  hash.merge({:id => doc[:_id]})
}.reduce({}){|memo, hash|
  memo[hash[:url]] = {
    title: hash[:title],
    id:    hash[:id]
  }
  memo
}

File.write("src/matchers.rb", jurisdictions)
