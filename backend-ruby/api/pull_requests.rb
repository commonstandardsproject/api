require 'grape'
require_relative '../config/mongo'
require_relative '../lib/securerandom'
require_relative 'entities/pull_request'
require_relative 'entities/pull_request_summary'
require_relative "../models/pull_request"

module API
  class PullRequests < Grape::API
    namespace :pull_requests do

      post "/" do
        validate_token
        model = PullRequest.create(@user, params[:standardSetId])

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
          status 422
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
        unless PullRequest.can_edit?(model, @user)
          status 401
          return
        end
        PullRequest.change_status(params[:id], "approval-requested", "Thanks so much! We'll take a look and get back to you in the next week (if not sooner)", true)
        present :data, PullRequest.find(params[:id]), with: Entities::PullRequest
      end

      post "/:id/change_status" do
        validate_token
        unless @user["isCommitter"]
          status 401
          return
        end
        PullRequest.change_status(params[:id], params[:status], params[:message], true)
        present :data, PullRequest.find(params[:id]), with: Entities::PullRequest
      end

      post "/:id/comment" do
        validate_token
        model = PullRequest.find(params[:id])
        unless PullRequest.can_edit?(model, @user)
          status 401
          return
        end
        PullRequest.add_comment(model, params[:comment], @user)
        present :data, PullRequest.find(params[:id]), with: Entities::PullRequest
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

        opts = { projection: { title: 1, status: 1, updatedAt: 1, createdAt: 1 } }

        models = PullRequest.find_query(query, opts)

        present :data, models, with: Entities::PullRequestSummary
      end

      get "/" do
        validate_token
        models = PullRequest.find_all_active
        present :data, models, with: Entities::PullRequest
      end

    end
  end
end
