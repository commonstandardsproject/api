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
      expose :cspStatus, safe: true do
        expose :value, safe: true
        expose :notes, safe: true
      end
      expose :license, safe: true do
        expose :title, safe: true
        expose :URL, safe: true
        expose :rightsHolder, safe: true
      end
      expose :document, safe: true do
        expose :title, safe: true
        expose :sourceURL, safe: true
      end
      expose :jurisdiction, safe: true do
        expose :title, safe: true
        expose :id, safe: true
      end

      expose :standards_map, as: :standards

      private
      def standards_map
        standards = object[:standards] || {}
        standards.reduce({}) {|map, kv|
          map[kv[0]] = kv[1].to_hash
          map
        }
      end

      # expose :standards, documentation: {desc: "A map of standards"} do |doc, options|

      # end
    end
  end
end
