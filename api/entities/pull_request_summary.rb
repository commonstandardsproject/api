require 'grape-entity'
require_relative './activity'

module API
  module Entities
    class PullRequestSummary < Grape::Entity

      expose :id
      expose :createdAt
      expose :updatedAt
      expose :title
      expose :status
    end
  end
end
