require 'bundler/setup'
require 'grape-entity'
require_relative 'standards_document_summary'
require_relative 'standard_set_summary'


module API
  module Entities
    class Jurisdiction < Grape::Entity

      expose :_id, as: :id
      expose :title
      expose :documents, with: Entities::StandardsDocumentSummary
      expose :standardSets, with: Entities::StandardSetSummary

    end
  end
end
