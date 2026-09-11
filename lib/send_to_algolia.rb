require 'pp'
require 'active_support/core_ext/hash/slice'
require_relative "../config/algolia"
require_relative "../config/mongo"
require_relative "../lib/standard_hierarchy"


class SendToAlgolia
  @@index = Algolia::Index.new("common-standards-project")

  # A whole standard set's worth of denormalized standards can be tens of
  # megabytes (each standard carries its ancestors' descriptions), so we send
  # them to Algolia in batches instead of building one giant request body.
  BATCH_SIZE = 500

  def self.all_standard_sets
    $db[:standard_sets].find(nil, {batch_size: 8}).each {|set|
      p "Sending to Algolia #{set["jurisdiction"]["title"]}: #{set["title"]}"
      self.standard_set(set)
    }
  end

  def self.standard_set(set)
    return if ENV["ENVIRONMENT"] == "development"
    self.each_denormalized_batch(set){|batch|
      @@index.add_objects(batch)
    }
  end

  def self.denormalize_standards(standardSet)
    standards = []
    self.each_denormalized_batch(standardSet){|batch| standards.concat(batch) }
    standards
  end

  def self.each_denormalized_batch(standardSet, batch_size = BATCH_SIZE)
    return if standardSet["standards"].nil? || standardSet["standards"].empty?

    standards = StandardHierarchy.sort_standards(standardSet["standards"])
    ancestors_by_index = StandardHierarchy.ancestors_for(standards)

    publication_status = nil
    if standardSet["document"] != nil && standardSet["document"]["publicationStatus"] != nil
      publication_status = standardSet["document"]["publicationStatus"]
    end

    batch = []
    standards.each_with_index{|standard, i|
      ancestors = ancestors_by_index[i]
      ancestor_ids = ancestors.map{|a| a["id"]}
      batch.push(standard.merge({
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
      }))

      if batch.length >= batch_size
        yield batch
        batch = []
      end
    }

    yield batch unless batch.empty?
  end

end
