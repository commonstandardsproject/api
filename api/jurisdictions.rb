require 'grape'
require_relative '../config/mongo'
require_relative 'entities/jurisdiction'
require_relative '../models/jurisdiction'
require_relative 'entities/jurisdiction_summary'

module API
  class Jurisdictions < Grape::API
    format :json
    namespace :jurisdictions, desc: "A state, organization, district, or school" do

      desc "Return a list of jurisdictions"
      get "/" do
        jurisdictions = $db[:jurisdictions].find({
          :$or => [
            {:$and => [
              {:status => {:$ne => "inactive"}},
              {:status => {:$ne => "pending"}},
              {:status => {:$ne => "rejected"}} ] },
            {:submitterId => @user["id"]}
          ]
        }).sort({:title => 1}).to_a
        present :data, jurisdictions, with: Entities::JurisdictionSummary
      end

      desc "Return a jurisdiction", entity: Entities::Jurisdiction
      params do
        requires :id, type: String, desc: "ID", default: "49FCDFBD2CF04033A9C347BFA0584DF0"
      end
      get "/:id" do
        jurisdiction = $db[:jurisdictions].find({
          :_id => params[:id],
        }).to_a.first


        standardSets = $db[:standard_sets].find({
          "jurisdiction.id" => params[:id],
          "cspStatus.value" => {"$ne" => "hidden"}
        }).projection({
          "_id" => 1,
          "title" => 1,
          "subject" => 1,
          "document" => 1,
          "educationLevels" => 1
        }).to_a
        jurisdiction["standardSets"] = standardSets


        # We're tenatively taking out standard_documents from the response
        # documents = $db[:standard_documents].find({
        #   "document.jurisdictionId" => params[:id]
        # }).projection("_id" => 1, "document.title" => 1).to_a
        # jurisdiction["documents"]    = documents

        present :data, jurisdiction, with: Entities::Jurisdiction
      end

      post "/", hidden: true do
        validate_token
        jurisdiction= Jurisdiction.new(params[:jurisdiction].to_hash)
        jurisdiction.status = "pending"
        jurisdiction.submitterId = @user["id"]
        Jurisdiction.insert(jurisdiction)
        present :data, jurisdiction, with: Entities::Jurisdiction
      end

    end
  end
end
