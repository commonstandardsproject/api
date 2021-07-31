require 'bundler/setup'
require 'grape-entity'
require_relative "../../models/standard_set"

module API
  module Entities
    class StandardSet < Grape::Entity
      expose :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "An array of education levels", values: ::StandardSet::EDUCATION_LEVELS }
      expose :license
      expose :document
      expose :jurisdiction

      expose :standards, documentation: {desc: "A map of standards"} do |doc|
        doc[:standards] || {}
      end
    end
  end
end
