require 'bundler/setup'
require 'grape-entity'
require_relative 'standards_document_summary'


module API
  module Entities
    class Jurisdiction < Grape::Entity

      expose :_id, as: :id
      expose :title
      expose :documents, with: Entities::StandardsDocumentSummary

    end
  end
end
