require 'grape-entity'
require_relative './activity'

module API
  module Entities
    class PullRequest < Grape::Entity

      expose :id
      expose :createdAt
      expose :updatedAt
      expose :title
      expose :submitterId
      expose :submitterEmail
      expose :submitterName
      expose :activities, using: API::Entities::Activity
      expose :forkedFromStandardSetId
      expose :statusComment

      # just standardSetId instead
      expose :standardSet, using: API::Entities::StandardSet
      expose :status
    end
  end
end
