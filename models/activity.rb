require_relative "../lib/securerandom"
require 'dry-validation'

class Activity
  include Virtus.model

  attribute :id, String, :default => -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :createdAt, DateTime, :default => lambda { Time.now }
  attribute :type, String
  attribute :title, String

  class Validator < Dry::Validation::Schema
    key(:createdAt, &:date_time?)
    key(:type, &:str?)
    key(:title, &:str?)
  end

end
