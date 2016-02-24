require 'bundler/setup'
require 'grape-entity'
require_relative "../../models/standard_set"

module API
  module Entities
    class StandardSet < Grape::Entity
      expose :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "An array of education levels", values: ::StandardSet::EDUCATION_LEVELS } {|val| (val && val.kind_of?(Array)) ? val : []}
      expose :license
      expose :document
      expose :jurisdiction

      expose :standards, documentation: {desc: "A map of standards"} {|doc|
        doc[:standards] || {}
      }
    end
  end
end
