require 'grape-entity'

module API
  module Entities
    class PullRequest < Grape::Entity

      expose :id
      expose :createdAt
      expose :updatedAt
      expose :summary
      expose :submitterId
      expose :submitterEmail
      expose :submitterName
      expose :activities
      expose :forkedFromStandardSetId

      # just standardSetId instead
      expose :standardSet, using: API::Entities::StandardSet
      expose :status
    end
  end
end
