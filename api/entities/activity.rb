require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class Activity < Grape::Entity
      expose :id
      expose :createdAt
      expose :type
      expose :status
      expose :title
      expose :userId
      expose :userName
    end
  end
end
