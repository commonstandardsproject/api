require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardSetSummary < Grape::Entity
      expose :_id, as: :id
      expose :title, documentation: {desc: "The name of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "The education levels", is_array: true}
      expose :document
      # expose :documentTitle
    end
  end
end
