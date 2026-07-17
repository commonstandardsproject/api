require 'pp'
require 'active_support/core_ext/hash/slice'
require_relative "../config/algolia"
require_relative "../config/mongo"
require_relative "../lib/standard_hierarchy"


class SendToAlgolia
  @@index = Algolia::Index.new("common-standards-project")

  def self.all_standard_sets
    # slices = []
    sets = []
    puts $db[:standard_sets].find(nil, {batch_size: 32}).each {|set|
      sets.push(set)
      if sets.length == 32
        puts "Has 32 sets. Now processing."
        Parallel.map(sets, in_threads: 32){|set|
          p "Denormalizing #{set["jurisdiction"]["title"]}: #{set["title"]}"
          standards = self.denormalize_standards(set)
          p "Sending to Algolia #{set["jurisdiction"]["title"]}: #{set["title"]}"
          @@index.add_objects(standards)
        }
        sets = []
      end
    }
  end

  def self.standard_set(set)
    return if ENV["ENVIRONMENT"] == "development"
    @@index.add_objects(self.denormalize_standards(set))
  end

  def self.denormalize_standards(standardSet)
    # Reversed because (for whatever reason), I find it easier to think about
    # this algorithm if I move from up (instead of down) a tree
    standards = standardSet["standards"].values.reject{|s| s == ""}.sort_by{|s| s["position"].to_i}.reverse

    publication_status = nil
    if standardSet["document"] != nil && standardSet["document"]["publicationStatus"] != nil
      publication_status = standardSet["document"]["publicationStatus"]
    end
    standards.each_with_index.map{|standard, i|
      ancestors = StandardHierarchy.find_ancestors(standards, standard, i)
      ancestor_ids = ancestors.map{|a| a["id"]}
      standard.merge({
        objectID:             standard["id"],
        ancestorIds:          ancestor_ids,
        ancestorDescriptions: ancestors.map{|a| a["description"]},
        educationLevels:      standardSet["educationLevels"],
        subject:              standardSet["subject"],
        normalizedSubject:    standardSet["normalizedSubject"],
        standardSet:          {
          title: standardSet["title"],
          id: standardSet["_id"]
        },
        jurisdiction: standardSet["jurisdiction"],
        document: {
          publicationStatus: publication_status
        },
        _tags: [ancestor_ids, standardSet["_id"], standardSet["jurisdiction"]["id"], standardSet["educationLevels"]].flatten
      })
    }
  end

end
