require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardsSet < Grape::Entity
      expose :_id, as: :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :educationLevels, documentation: {desc: "An array of education levels", is_array: true}
      expose :license do
        expose :title, documentation: {desc: "The license the standards are available in"}
        expose :URL, documentation: {desc: "The url the license can be fetched at"}
        expose :attributionURL, documentation: {desc: "The url to attribute "}
      end
      expose :rightsHolder, documentation: {desc: "The holder of the copyright"}
      expose :document do
        expose :id, documentation: {desc: "The id of the standards document that these standards were extracted from."}
        expose :title, documentation: {desc: "The name of the standards document that these standards were extracted from."}
        expose :sourceURL, documentation: {desc: "The URL of the document the standards were extracted from."}
      end
      expose :jurisdiction do
        expose :id, documentation: {desc: "The id of the jurisdiction"}
        expose :title, documentation: {desc: "The name of the jurisdiction"}
      end

      expose :standards, documentation: {desc: "A map of standards"}
    end
  end
end
