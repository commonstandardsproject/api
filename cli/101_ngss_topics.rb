require 'bundler/setup'
require 'oj'
require 'pp'


docs = Oj.load(File.read('sources/ngss_topics.json'))
pp docs["rdf:RDF"]["skos:Concept"].reduce({}) {|memo, el|
  url       = [el["-rdf:about"]].flatten.first
  memo.merge({url => [el["skos:prefLabel"]].flatten.first["#text"]})
}
