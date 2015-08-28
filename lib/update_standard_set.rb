require 'pp'
require 'securerandom'
require_relative 'cache_standards'
require_relative 'send_to_algolia'

class UpdateStandardSet


  def self.update(doc, opts)
    old_version    = $db[:standard_sets].find({_id: doc["id"]}).to_a.first || {}
    if old_version["version"] && old_version["version"] > 0
      self.save_version(old_version)
    end

    # Set the version
    doc["version"] = old_version["version"] || 0

    # Set the ID
    doc["_id"]     = doc.delete("id")

    # Replace the document
    doc = $db[:standard_sets].find({_id: doc["_id"]}).find_one_and_update(doc, {upsert: true, return_document: :after})

    # Cache standards
    unless opts[:cache_standards] == false
      CachedStandards.one(doc)
    end

    # Send to algolia
    unless opts[:send_to_algolia] == false
      SendToAlgolia.standard_set(doc)
    end
  end

  def self.with_delta(id, ops)
    old_version = $db[:standard_sets].find({_id: id}).to_a.first

    if old_version
      self.save_version(old_version)
    end

    operations = ops.reduce({}){|acc, hash|
      acc[hash["op"]] ||= {}
      acc[hash["op"]][hash["path"]] = hash["value"]
      acc
    }
    operations["$inc"] ||= {}
    operations["$inc"]["version"] = 1
    operations["$set"] ||={}
    operations["$set"]["updatedAt"] = Time.now
    doc = $db[:standard_sets].find({_id: id}).find_one_and_update(operations, return_document: :after)

    # Cache standards
    CachedStandards.one(doc)

    # Send to algolia
    unless ENV["ENVIRONMENT"] == "development"
      SendToAlgolia.standard_set(doc)
    end
  end

  def self.save_version(old_version)
    old_version["standardSetId"] = old_version["_id"]
    old_version["_id"] = SecureRandom.uuid().to_s.gsub("-", "").upcase
    $db[:standard_set_versions].insert_one(old_version)
  end

end
