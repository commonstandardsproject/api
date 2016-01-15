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
      expose :comments
      expose :standardSet
      expose :isApplied
      expose :status
    end
  end
end
