require 'grape'
require_relative '../config/mongo'
require_relative '../lib/securerandom'
require_relative 'entities/pull_request'

module API
  class PullRequests < Grape::API
    namespace :pull_requests do

      post "/" do
        validate_token
        PullRequest.create(@user, params.standard_set_id)
        PullRequest.add_activity(model, Activity.new({
          type: "created",
          title: "Woohoo! New pull request created by #{@user['profile']['name']}"
        }))
        # return it
        present :data, model, with: Entities::PullRequest
      end

      post "/:id" do
        validate_token
        model = PullRequest.find(params[:id])
        return 401 unless PullRequest.can_edit?(model, @user)
        model = PullRequest.update(params[:data])
        # PullRequest.add_activity(model, Activity.new({
        #   type: "saved",
        #   title: "Saved by #{@user['profile']['name']}"
        # }))
        present :data, model, with: Entities::PullRequest
      end

      post "/:id/submit" do
        validate_token
        model = PullRequest.find(params[:id])
        return 401 unless PullRequest.can_edit?(model, @user)
        PullRequest.change_status(params[:id], "in-review", true)
      end

      post "/:id/change-status" do
        validate_token
        return 401  unless @user["committer"] === true
        PullRequest.change_status(params[:id], params[:status], params[:message], true)
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
        validate_token
        models = PullRequest.find_all
        present :data, models, with: Entities::PullRequest
      end

    end
  end
end
