require 'bundler/setup'
require 'grape-entity'
require "../models/standard_set"

module API
  module Entities
    class StandardSet < Grape::Entity
      expose :_id, as: :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "An array of education levels", values: StandardSet.EDUCATION_LEVELS } {|val| (val && val.kind_of?(Array)) ? val : []}
      expose :license
      expose :document
      expose :jurisdiction

      expose :standards, documentation: {desc: "A map of standards"} {|_| _ || {} }
    end
  end
end
