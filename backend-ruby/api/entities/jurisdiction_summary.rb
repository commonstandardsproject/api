require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class JurisdictionSummary < Grape::Entity

      expose :_id, as: :id, documentation: {type: "string", desc: "id"}
      expose :title, documentation: {type: "string", desc: "The name of the jurisdiction"}
      expose :type, documentation: {type: "string", desc: "The type of jurisdiction", values: ["organization", "state", "school"]}

    end
  end
end
