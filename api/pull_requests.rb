require 'grape'
require_relative '../config/mongo'
require_relative '../lib/securerandom'
require_relative 'entities/pull_request'
require_relative "../models/pull_request"

module API
  class PullRequests < Grape::API
    namespace :pull_requests do

      post "/" do
        validate_token
        model = PullRequest.create(@user, params[:standard_set_id])

        # reload it
        model = PullRequest.find(model.id)

        # return it
        present :data, model, with: Entities::PullRequest
      end

      post "/:id" do
        validate_token
        model = PullRequest.find(params[:id])
        return 401 unless PullRequest.can_edit?(model, @user)
        success, response = PullRequest.user_update(params[:data])
        if success === false
          return {
            errors: response.map{|field, (expected, actual)|
              "#{expected.first} but we received #{actual.to_s}"
            }
          }
        else
          present :data, response, with: Entities::PullRequest
        end
      end

      post "/:id/submit" do
        validate_token
        model = PullRequest.find(params[:id])
        return 401 unless PullRequest.can_edit?(model, @user)
        PullRequest.change_status(params[:id], "approval-requested", nil, true)
      end

      post "/:id/change_status" do
        validate_token
        return 401  unless @user["committer"] === true
        PullRequest.change_status(params[:id], params[:status], params[:message], true)
      end

      post "/:id/comment" do
        validate_token
        model = PullRequest.find(params[:id])
        return 401 unless PullRequest.can_edit?(model, @user)
        PullRequest.add_comment(model, params[:comment], @user)
      end

      get "/:id" do
        validate_token

        model = PullRequest.find(params[:id])
        present :data, model, with: Entities::PullRequest
      end

      get "/user/:user_id" do
        query = {
          status: {:$ne => "rejected"},
          submitterId: params[:user_id]
        }

        models = PullRequest.find_query(query)

        present :data, models, with: Entities::PullRequest
      end

      get "/" do
        validate_token
        models = PullRequest.find_all_active
        present :data, models, with: Entities::PullRequest
      end

    end
  end
end
