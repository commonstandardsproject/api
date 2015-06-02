require 'pp'
class UpdateStandardsSet


  def self.update(doc)
    old_version = $db[:new_standard_sets].find({_id: doc["id"]}).to_a.first
    # if old_version
      # update the version
      # doc["version"] = old_version["version"] + 1

      # append the version
      # old_version["_id"] = old_version["_id"] + "_version-" + old_version["version"].to_s

      # insert the version
      # $db[:standard_set_versions].insert_one(old_version)
    # else
      # doc["version"] = 0
    # end
    doc["version"] = 0


    doc["_id"] = doc.delete("id")
    $db[:new_standard_sets].find({_id: doc["_id"]}).replace_one(doc, {upsert: true})
  end

end
