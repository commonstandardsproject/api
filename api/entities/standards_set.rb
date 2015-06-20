require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardsSet < Grape::Entity
      expose :_id, as: :id
      expose :title
      expose :subject
      expose :educationLevels
      expose :license
      expose :licenseURL
      expose :attributionURL
      expose :rightsHolder
      expose :documentId
      expose :documentTitle
      expose :jurisdictionId
      expose :jurisdiction
      expose :source
      expose :standards
    end
  end
end
