class User
  include Virtus.model

  attribute :profile, Hash
  attribute :email, String
  attribute :apiKey, String
  attribute :algoliaApiKey, String
  attribute :allowedOrigins, Array[String]

  def self.find(id)
    user = $db[:users].find({_id: id}).to_a.first
    self.new(user)
  end

end
