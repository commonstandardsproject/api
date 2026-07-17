require 'bundler/setup'
require 'grape-entity'
require_relative 'standard_document_summary'
require_relative 'standard_set_summary'


module API
  module Entities
    class Jurisdiction < Grape::Entity

      expose :id ,documentation: {type: "string", desc: "id"} do |doc, options|
        doc[:id] || doc[:_id]
      end
      expose :title, documentation: {type: "string", desc: "The name of the jurisdiction"}
      expose :type, documentation: {type: "string", desc: "The type of jurisdiction", values: ["organization", "state", "school"]}
      # expose :documents, with: Entities::StandardDocumentSummary
      expose :standardSets, with: Entities::StandardSetSummary, documentation: {desc: "Standards Sets", param_type: 'body', is_array: true}

    end
  end
end
