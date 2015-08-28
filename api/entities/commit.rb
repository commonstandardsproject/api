require 'bundler/setup'
require 'grape-entity'


module API
  module Entities
    class Commit < Grape::Entity

      expose :_id, as: :id do |commit, options|
        commit[:_id].to_s
      end
      expose :committerName
      expose :committerEmail
      expose :commitSummary
      expose :standardSetTitle
      expose :standardSetId
      expose :jurisdictionTitle
      expose :jurisdictionId
      expose :createdOn
      expose :ops

    end
  end
end
