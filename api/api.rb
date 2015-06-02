require 'bundler/setup'
require 'grape'
require 'mongo'
require 'pp'
require 'oj'
require_relative 'entities/jurisdiction'
require_relative 'entities/standards_document_summary'
require_relative 'entities/standards_document'
require_relative '../src/transformers/query_to_standard_set'
require_relative "../src/update_standards_set"

module API
  class API < Grape::API

    format :json
    prefix :api


    get "jurisdiction" do
      jurisdictions = $db[:jurisdictions].find({cachedDocumentIds: {:$ne => nil}}).sort({:title => 1}).to_a
      present :jurisdictions, jurisdictions, with: Entities::Jurisdiction
    end



    get "jurisdictions/:id" do
      jurisdiction = $db[:jurisdictions].find({
        :_id => params[:id]
      }).to_a.first
      documents = $db[:standards_documents].find({
        "document.jurisdictionId" => params[:id]
      }).projection("_id" => 1, "document.title" => 1).to_a
      jurisdiction["documents"] = documents
      present jurisdiction, with: Entities::Jurisdiction
    end


    get "standards_document/:id" do
      document = $db[:standards_documents].find({
        :_id => params[:id]
      }).projection(
        "_id" => 1,
        "document" => 1,
        "documentMeta" => 1,
        "standardsSetQueries" => 1
      ).to_a.first

      present document, with: Entities::StandardsDocument
    end

    post "standards_set/" do
      standards_doc = $db[:standards_documents].find({
        :_id => params.standardsDocumentId
      }).to_a.first

      QueryToStandardSet.generate(standards_doc, params.query.to_hash)
    end

    post "standards_set_import" do
      standards_doc = $db[:standards_documents].find({
        :_id => params.standardsDocumentId
      }).to_a.first

      set = QueryToStandardSet.generate(standards_doc, params.query.to_hash)
      UpdateStandardsSet.update(set)
    end



  end
end
