require 'bundler/setup'
require 'grape'
require 'mongo'
require 'pp'
require 'oj'
require 'grape_logging'
require_relative '../lib/securerandom'
require_relative 'entities/jurisdiction'
require_relative 'entities/standards_document_summary'
require_relative 'entities/standards_document'
require_relative 'entities/standards_set'
require_relative '../src/transformers/query_to_standard_set'
require_relative "../src/update_standards_set"
require_relative "../lib/validate_token"

module API
  class API < Grape::API

    logger.formatter = ::GrapeLogging::Formatters::Default.new
    use ::GrapeLogging::Middleware::RequestLogger, { logger: logger }

    format :json
    prefix :api


    # rescue_from :all do |e|
    #   logger.error e
    # end


    # Authentication
    # Make sure each request has an auth token and originates from
    # an origin specified in the user's document

    before do
      token = headers["Auth-Token"] || params["auth-token"]

      user = $db[:users].find({apiToken: token}).find_one_and_update({
        "$inc" => {requestCount: 1}
      })
      if user.nil?
        error!('Unauthorized: Not a valid auth token. Sign up at commonstandardsproject.com', 401)
        return
      end
      if user[:allowedOrigins].include?(env["HTTP_ORIGIN"]) == false
        error!("Unauthorized: Origin isn't an allowed origin.", 401)
      end
    end



    namespace :users do
      post "/signed_in" do
        user = $db[:users].find({email: params[:profile][:email]}).find_one_and_update({
          "$inc" => {signInCount:  1},
          "$set" => {
            profile: params[:profile],
          },
          "$setOnInsert" => {
            "_id" => SecureRandom.uuid().to_s.upcase.gsub('-', ''),
            "allowedOrigins" => []
          }
        }, {upsert: true, return_document: :after})

        if user[:apiToken].nil?
          user = $db[:users].find({_id: user[:_id]}).find_one_and_update({
            "$set" => {apiToken: SecureRandom.base58(24)}
          }, {return_document: true})
        end
        user
      end


    end



    namespace :jurisdictions do

      get "/" do
        jurisdictions = $db[:jurisdictions].find({cachedDocumentIds: {:$ne => nil}}).sort({:title => 1}).to_a
        present :data, jurisdictions, with: Entities::Jurisdiction
      end

      get "/:id" do
        # begin
        #   ValidateToken.validate(headers)
        # rescue InvalidTokenError => e
        #   error!('Invalid Token', 401)
        # end

        jurisdiction = $db[:jurisdictions].find({
          :_id => params[:id]
        }).to_a.first
        documents = $db[:standards_documents].find({
          "document.jurisdictionId" => params[:id]
        }).projection("_id" => 1, "document.title" => 1).to_a

        standardSets = $db[:new_standard_sets].find({
          "jurisdictionId" => params[:id]
        }).projection("_id" => 1, "title" => 1, "subject" => 1, "sourceURL" => 1, "documentTitle" => 1).to_a

        jurisdiction["documents"]    = documents
        jurisdiction["standardSets"] = standardSets
        present :data, jurisdiction, with: Entities::Jurisdiction
      end

    end

    namespace :standards_documents do
      get ":id" do
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

    end




      get "/standard_sets/:id" do
        begin
          ValidateToken.validate(headers)
        rescue InvalidTokenError => e
          error!('Invalid Token', 401)
        end

        standards_set = $db[:new_standard_sets].find({
          :_id => params.id
        }).to_a.first

        standards_set[:jurisdiction] = $db[:jurisdictions].find({_id: standards_set[:jurisdictionId]}).to_a.first[:title]

        present :data, standards_set, with: Entities::StandardsSet
      end


      post "/" do
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
