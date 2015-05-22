require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardsDocumentSummary < Grape::Entity
      expose :_id, as: :id

      expose :title do |doc, options|
        doc["document"]["title"]
      end

      expose :standardSetQueries

    end
  end
end
