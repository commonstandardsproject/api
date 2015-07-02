require 'bundler/setup'
require 'grape'
require 'grape-swagger'
require 'mongo'
require 'pp'
require 'oj'
require 'grape_logging'
require 'algoliasearch'
require_relative '../lib/securerandom'
require_relative 'entities/jurisdiction'
require_relative 'entities/standards_document_summary'
require_relative 'entities/standards_document'
require_relative 'entities/standard_set'
require_relative 'entities/commit'
require_relative 'entities/user'
require_relative '../src/transformers/query_to_standard_set'
require_relative "../src/update_standard_set"
require_relative "../lib/validate_token"

module ApiKeyAuthentication
  extend Grape::API::Helpers

  # Authentication
  # Make sure each request has an auth token and originates from
  # an origin specified in the user's document
  # before do
  #   key = headers["Api-Key"] || params["api-key"]
  #
  #   user = $db[:users].find({apiKey: key}).find_one_and_update({
  #     "$inc" => {requestCount: 1}
  #   })
  #   if user.nil?
  #     error!('Unauthorized: Not a valid auth key. Sign up at commonstandardsproject.com', 401)
  #     return
  #   end
  #   if env["HTTP_ORIGIN"] && user[:allowedOrigins].include?(env["HTTP_ORIGIN"]) == false
  #     error!("Unauthorized: Origin isn't an allowed origin.", 401)
  #   end
  # end

end

module API
  class API < Grape::API

    # add_swagger_documentation base_path: "/api",
    #                       api_version: 'v1',
    #                       hide_documentation_path: true

    logger.formatter = ::GrapeLogging::Formatters::Default.new
    use ::GrapeLogging::Middleware::RequestLogger, { logger: logger }

    format :json
    prefix :api

    desc "Users", hidden: true
    namespace :users, hidden: true do

      get "/:email", requirements: {email:  /.+@.+/}  do
        user = $db[:users].find({email: params[:email]}).to_a.first
        present :data, user, with: Entities::User
      end

      post "/signed_in", hidden: true do
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

        if user[:algoliaApiKey].nil?
          #  Algolia.generate_secured_api_key(user[:email])
          index = Algolia::Index.new('common-standards-project')
          key = index.add_user_key({
            :maxQueriesPerIPPerHour => 200,
            :indexes                => ["common-standards-project"],
            :acl                    => ["search"],
            :description            => "#{user[:email]} - #{user[:profile][:name]} - Limited to searching standards"
          })
          user = $db[:users].find({_id: user[:_id]}).find_one_and_update({
            "$set" => {algoliaApiKey: key["key"]}
          }, {return_document: true})
        end

        if user[:apiKey].nil?
          user = $db[:users].find({_id: user[:_id]}).find_one_and_update({
            "$set" => {apiKey: SecureRandom.base58(24)}
          }, {return_document: true})
        end
        present :data, user, with: Entities::User
      end

      post "/:id/allowed_origins", hidden: true do
        user = $db[:users].find({_id: params[:id]}).find_one_and_update({
          "$set" => {allowedOrigins: params[:data]}
        }, {return_document: true})
        present :data, user, with: Entities::User
      end

    end

    namespace :commits do
      post "/", hidden: true do
        data = {
          _id:               SecureRandom.uuid().to_s.gsub("-", "").upcase,
          applied:           false,
          createdOn:         Time.now,
          committerName:     params[:data]["committerName"],
          committerEmail:    params[:data]["committerEmail"],
          commitSummary:     params[:data]["commitSummary"],
          standardSetId:    params[:data]["standardSetId"],
          standardSetTitle: params[:data]["standardSetTitle"],
          jurisdictionTitle: params[:data]["jurisdictionTitle"],
          jurisdictionId:    params[:data]["jurisdictionId"],
          diff:              params[:data]["diff"],
        }
        $db[:commits].insert_one(data)
        return 201
      end

      post "/approval/:id", hidden: true do
        commit = $db[:commits].find({:_id => params[:id]}).to_a.first
        if commit[:applied]
          return 201
        end
        diff = commit["diff"]
        diff["$set"] = diff["$set"] || {}
        diff["$set"]["commit"] = {
          "committerName"  => commit["committerName"],
          "committerEmail" => commit["committerEmail"],
          "commitSummary"  => commit["commitSummary"],
          "commitId"       => params[:id],
        }
        diff["$set"]["updatedOn"] = Time.now
        UpdateStandardSet.with_delta(commit[:standardSetId], diff)
        $db[:commits].find({:_id => params[:id]}).update_one({"$set" => {:applied => true}})
      end

      get "/", hidden: true do
        commits = $db[:commits].find({applied: false}).to_a
        present :data, commits, with: Entities::Commit
      end

    end


    namespace :jurisdictions, desc: "State, Organization, or School" do

      desc "Return a list of jurisdictions"
      get "/" do
        jurisdictions = $db[:jurisdictions].find({status: {:$ne => "inactive"}}).sort({:title => 1}).to_a
        present :data, jurisdictions, with: Entities::Jurisdiction
      end

      desc "Return a jurisdiction", entity: Entities::Jurisdiction
      params do
        requires :id, type: String, desc: "ID", default: "49FCDFBD2CF04033A9C347BFA0584DF0"
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
          "jurisdiction.id" => params[:id]
        }).projection("_id" => 1, "title" => 1, "subject" => 1, "sourceURL" => 1, "documentTitle" => 1, "educationLevels" => 1).to_a

        jurisdiction["documents"]    = documents
        jurisdiction["standardSets"] = standardSets
        present :data, jurisdiction, with: Entities::Jurisdiction
      end

      post "/", hidden: true do
        jurisdiction = params[:jurisdiction].to_hash
        jurisdiction[:status] = "pending"
        jurisdiction[:_id] = SecureRandom.uuid().to_s.gsub("-", "").upcase
        new_jurisdiction = $db[:jurisdictions].insert_one(jurisdiction)
        present :data, jurisdiction, with: Entities::Jurisdiction
      end

    end

    namespace :standards_documents, hidden: true do
      get ":id", hidden: true do
        document = $db[:standards_documents].find({
          :_id => params[:id]
        }).projection(
          "_id" => 1,
          "document" => 1,
          "documentMeta" => 1,
          "standardSetQueries" => 1
        ).to_a.first

        present document, with: Entities::StandardsDocument
      end

    end




    namespace "/standard_sets", desc: "A set of standards typically grouped by grade level & subject" do

      desc "Fetch a standards set", entity: Entities::StandardSet
      params do
        requires :id, type: String, desc: "ID", default: "49FCDFBD2CF04033A9C347BFA0584DF0_D2604890_grade-01"
      end
      get "/:id" do
        standard_set = $db[:new_standard_sets].find({
          :_id => params.id
        }).to_a.first

        p standard_set

        # standard_set[:jurisdictionTitle] = $db[:jurisdictions].find({_id: standard_set[:jurisdiction][:id]}).to_a.first[:title]

        present :data, standard_set, with: Entities::StandardSet
      end


      post "/", hidden: true do
        begin
          ValidateToken.validate(headers)
        rescue InvalidTokenError => e
          error!('Invalid Token', 401)
        end
        standards_doc = $db[:standards_documents].find({
          :_id => params.standardsDocumentId
        }).to_a.first

        QueryToStandardSet.generate(standards_doc, params.query.to_hash)
      end


    end


    post "standard_set_import", hidden: true do
      standards_doc = $db[:standards_documents].find({
        :_id => params.standardsDocumentId
      }).to_a.first

      set = QueryToStandardSet.generate(standards_doc, params.query.to_hash)
      UpdateStandardSet.update(set)

      add_swagger_documentation
    end




    add_swagger_documentation api_version: "v1",
                              hide_format: true,
                              hide_documentation_path: true,
                              models: [Entities::Jurisdiction, Entities::StandardSetSummary, Entities::StandardSet]

  end
end
