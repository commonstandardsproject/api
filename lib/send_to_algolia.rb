require 'pp'
require 'algoliasearch'
require 'active_support/core_ext/hash/slice'
require_relative "init_mongo"


Algolia.init :application_id => ENV["ALGOLIA_APPLICATION_ID"], :api_key => ENV["ALGOLIA_API_KEY"]

class SendToAlgolia
  @@index = Algolia::Index.new("common-standards-project")

  def self.all_standard_sets
    $db[:standard_sets].find().batch_size(20).map{|set|
      # @@index.add_objects(self.denormalize_standards(set))
      p "Denormalizing #{set["jurisdiction"]["title"]}: #{set["title"]}"
      self.denormalize_standards(set)
    }.flatten.each_slice(10000){|standards|
      p "Importing #{standards.length}"
      @@index.add_objects(standards)
    }
  end

  def self.standard_set(set)
    @@index.add_objects(self.denormalize_standards(set))
  end

  def self.denormalize_standards(standardSet)
    standards = standardSet["standards"].values.sort_by{|s| s["position"]}.reverse
    standards.each_with_index.map{|standard, i|
      last_standard = standard
      ancestors = standards[i+1..-1].inject([]){ |acc, ss|
        if ss["depth"] == 0
          acc.push(ss)
          break acc
        elsif ss["depth"] < last_standard["depth"]
          last_standard = ss
          next acc.push(ss)
        else
          next acc
        end
      }
      ancestor_ids = ancestors.map{|a| a["id"]}
      standard.merge({
        objectID:             standard["id"],
        ancestorDescriptions: ancestors.map{|a| a["description"]},
        educationLevels:      standardSet["educationLevels"],
        subject:              standardSet["subject"],
        normalizedSubject:    standardSet["normalizedSubject"],
        standardSet:          {
          title: standardSet["title"],
          id: standardSet["_id"]
        },
        jurisdiction: standardSet["jurisdiction"],
        _tags: [ancestor_ids, standardSet["_id"], standardSet["jurisdiction"]["id"], standardSet["educationLevels"]].flatten
      })
    }
  end

end
