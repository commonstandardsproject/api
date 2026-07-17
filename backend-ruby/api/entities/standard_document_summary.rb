require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardDocumentSummary < Grape::Entity
      expose :_id, as: :id

      expose :title do |doc, options|
        doc["document"]["title"]
      end

    end
  end
end
