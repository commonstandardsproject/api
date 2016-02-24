require 'virtus'
require_relative "../lib/securerandom"

class User
  include Virtus.model

  attribute :profile, Hash
  attribute :email, String
  attribute :apiKey, String, default: -> (page, attrs){ SecureRandom.base58(24) }
  attribute :algoliaApiKey, String
  attribute :allowedOrigins, Array[String], default: []

  def self.find(id)
    user = $db[:users].find({_id: id}).to_a.first
    self.new(user)
  end

  def self.create(attrs)
    attrs[:_id] ||= SecureRandom.csp_uuid()
    user = $db[:users].find({_id: attrs[:_id]}).find_one_and_update({
      "$set" => attrs
    }, {upsert: true, return_document: :after})
    self.new(attrs)

  end

end
