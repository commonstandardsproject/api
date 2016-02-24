require 'grape-entity'

module API
  module Entities
    class PullRequest < Grape::Entity
      expose :_id, as: :id
      expose :createdAt
      expose :summary
      expose :submitterId
      expose :authorEmail
      expose :authorName
      expose :activity

      # just standardSetId instead
      expose :standardSet, using: API::Entities::StandardSet
      expose :isApplied
      expose :status
    end
  end
end
