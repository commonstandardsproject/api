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
      expose :cspStatus, safe: true do |doc, opts|
        (doc[:cspStatus] || {}).to_hash
      end
      expose :license, safe: true do |doc, opts|
        (doc[:license] || {}).to_hash
      end
      expose :document, safe: true do |doc, opts|
        (doc[:document] || {}).to_hash
      end
      expose :jurisdiction, safe: true do |doc, opts|
        (doc[:jurisdiction] || {}).to_hash
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

    end
  end
end
