require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardSet < Grape::Entity
      expose :_id, as: :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "An array of education levels", is_array: true}
      expose :license
      expose :rightsHolder, documentation: {desc: "The holder of the copyright"}
      expose :document
      expose :jurisdiction

      expose :standards, documentation: {desc: "A map of standards"}
    end
  end
end
