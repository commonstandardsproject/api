require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardsDocument < Grape::Entity

      expose :_id, as: :id
      expose :documentMeta
      expose :document
      expose :standardsSetQueries

    end
  end
end
