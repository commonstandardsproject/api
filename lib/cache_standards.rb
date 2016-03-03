require 'pp';
require 'parallel'
require_relative "../config/mongo";

class CachedStandards

  def self.all
    sets = $db[:standard_sets].find().batch_size(1000).map{|set|
      self.generate(set)
    }
    Parallel.map_with_index(sets){|set, index|
      p "Inserting set: #{index+1}"
      next if set.nil? || set.empty?
      $db[:cached_standards].bulk_write(set, :ordered => false)
    }
  end

  def self.one(set)
    cached = self.generate(set)
    return if cached.nil?
    $db[:cached_standards].bulk_write(cached, :ordered => false)
  end

  def self.generate(standardSet)
    p "Caching #{standardSet["jurisdiction"]["title"]} #{standardSet["subject"]} #{standardSet["title"]}"
    return if standardSet["standards"].nil? || standardSet["standards"].empty?
    standardSet["standards"].values.map{|s|
      {
        :replace_one => {
          :find => {_id: s["id"]},
          :replacement => {
            _id:             s["id"],
            standardSetId:   standardSet["_id"],
            asnIdentifier:   s["asnIdentifier"],
            educationLevels: standardSet["educationLevels"]
          },
          :upsert => true
        }
      }
    }
  end

end
