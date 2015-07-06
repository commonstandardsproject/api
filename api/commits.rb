require 'grape'
require_relative '../config/mongo'
require_relative '../lib/update_standard_set'
require_relative 'entities/commit'

module API
  class Commits < Grape::API
    namespace :commits do
      desc "Create a new commit to a standard set"
      post "/", hidden: true do
        validate_token
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

      desc "Approve a commit to a standard set and apply it (creating a new version in the process)"
      post "/:id/approve", hidden: true do
        validate_token
        if @user["committer"] != true
          error!("Cannot commit changes", 401)
        end
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
  end
end
