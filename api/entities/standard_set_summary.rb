require 'bundler/setup'
require 'grape-entity'

module API
  module Entities
    class StandardSetSummary < Grape::Entity
      expose :_id, as: :id
      expose :title
      expose :subject
      # expose :source
      # expose :documentTitle
    end
  end
end
