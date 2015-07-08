require 'pp'
require 'active_support/core_ext/hash/slice'
require_relative "../config/algolia"
require_relative "../config/mongo"


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
    # Reversed because (for whatever reason), I find it easier to think about
    # this algorithm if I move from up (instead of down) a tree
    standards = standardSet["standards"].values.sort_by{|s| s["position"]}.reverse

    standards.each_with_index.map{|standard, i|
      last_standard = standard
      ancestors = standards[i+1..-1].inject([]){ |acc, ss|

        # If it's a root standard, we're done here and can break
        if ss["depth"] == 0
          acc.push(ss)
          break acc

        # If the standard is a level above the last standard we pushed onto the ancestor array,
        # we add it to the ancestors array and set it to be the new last_standard
        elsif ss["depth"] < last_standard["depth"]
          last_standard = ss
          next acc.push(ss)

        # Otherwise, we'll just call next
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
