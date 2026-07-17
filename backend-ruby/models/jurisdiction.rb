require 'virtus_convert'
class Jurisdiction
  include Virtus.model

  attribute :id, String, :default => -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :title, String
  attribute :url, String
  attribute :type, String
  attribute :status, String
  attribute :submitterEmail, String
  attribute :submitterName, String
  attribute :submitterId, String
  attribute :standardSets

  def self.from_mongo(attrs)
    return nil if attrs.nil?
    attrs[:id] = attrs["_id"]
    attrs.delete("id")
    model = self.new(attrs)
    model
  end

  def self.insert(model)
    attrs = ::VirtusConvert.new(model).to_hash
    attrs[:_id] = attrs[:id]
    attrs.delete(:id)
    $db[:jurisdictions].insert_one(attrs)
  end

  def self.approve(id)
    $db[:jurisdictions].find({_id: id}).find_one_and_update({
      "$set" => {status: "approved"}
    })

  end

end
