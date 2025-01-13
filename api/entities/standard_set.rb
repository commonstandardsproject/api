require 'bundler/setup'
require 'grape-entity'
require_relative "../../models/standard_set"

module API
  module Entities
    class StandardSet < Grape::Entity
      expose :id
      expose :title, documentation: {desc: "Title of the set"}
      expose :subject, documentation: {desc: "The subject"}
      expose :normalizedSubject, documentation: {desc: "UNOFFICIAL: A normalized subject for standards imported from ASN (list: https://elastic1.asn.desire2learn.com/asn/scheme/ASNTopic/). These have not been entered for non-ASN standards. Also, this list might change in the future if this becomes an official field"}
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

      expose :standards_map_or_array, as: :standards

      private
      def standards_map_or_array
        standards = object[:standards] || {}
        if standards.is_a? Hash
          standards.reduce({}) {|map, kv|
            map[kv[0]] = kv[1].to_hash
            map
          }
        else
          standards.map{|standard| standard.to_hash}
        end
      end

    end
  end
end
