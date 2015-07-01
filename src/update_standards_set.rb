require 'pp'
class UpdateStandardsSet


  def self.update(doc)
    old_version    = $db[:new_standard_sets].find({_id: doc["id"]}).to_a.first || {}
    doc["version"] = old_version["version"] || 0
    doc["_id"]     = doc.delete("id")

    $db[:new_standard_sets].find({_id: doc["_id"]}).replace_one(doc, {upsert: true})
  end

  def self.with_delta(id, delta)
    old_version = $db[:new_standard_sets].find({_id: id}).to_a.first

    if old_version
      old_version["standardsSetId"] = id
      old_version.delete("_id")
      $db[:standard_set_versions].insert_one(old_version)
    end

    delta["$inc"] = delta["$inc"] || {}
    delta["$inc"]["version"] = 1
    p id
    p delta
    $db[:new_standard_sets].find({_id: id}).update_one(delta)

  end

end
