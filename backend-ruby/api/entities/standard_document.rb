require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardDocument < Grape::Entity

      expose :_id, as: :id
      expose :documentMeta
      expose :document
      expose :standardSetQueries

    end
  end
end
