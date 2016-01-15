require 'grape'
require_relative '../config/mongo'
require_relative '../lib/securerandom'
require_relative 'entities/pull_request'

module API
  class PullRequests < Grape::API
    namespace :pull_requests do

      post "/" do
        pp "POST"
        validate_token

        hash = params[:data] || {}

        # find
        model = $db[:pull_requests].find({_id: hash[:id]}).first

        # return if not authorized
        return 401 if model != nil && model["submitterId"] != @user["id"] || @user["committer"] == false

        # set defaults
        hash[:_id]            = hash.delete(:id)
        hash[:_id] ||= SecureRandom.csp_uuid() # ensure an id
        hash[:submitterId]    = @user["_id"]
        hash[:submitterEmail] = @user["email"]
        hash[:submitterName]  = @user["profile"]["name"]

        # upsert it
        model = $db[:pull_requests]
          .find({_id: hash[:_id]})
          .find_one_and_update({
            "$set": hash,
            "$setOnInsert" => {
              "createdAt" => Time.now
            }
          }, {upsert: true, return_document: :after})

        # return it
        present :data, model, with: Entities::PullRequest
      end

      get "/:id" do
        model = $db[:pull_requests].find({_id: params[:id]}).first
        present :data, model, with: Entities::PullRequest
      end

      get "/user/:user_id" do
        query = {
          status: {:$ne => "rejected"},
          submitterId: params[:user_id]
        }

        models = $db[:pull_requests].find(query).to_a

        present :data, models, with: Entities::PullRequest
      end

      get "/" do
        models = $db[:pull_requests].find({status: {:$ne => "rejected"}}).to_a
        present :data, models, with: Entities::PullRequest
      end

    end
  end
end
