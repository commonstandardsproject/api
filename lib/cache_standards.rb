require 'pp';
require 'date'
require_relative "../config/mongo";
require_relative "../lib/standard_hierarchy"

class CachedStandards

  # Large sets have tens of thousands of standards. Writing them in batches
  # keeps a bounded number of (fairly large) write operations in memory at a
  # time instead of building one array holding a copy of the whole set.
  BATCH_SIZE = 500

  def self.all
    $db[:standard_sets].find(nil, {batch_size: 8}).each_with_index{|set, index|
      p "Inserting set: #{index+1}"
      self.one(set)
    }
  end

  def self.one(set)
    self.each_write_batch(set){|batch|
      begin
        $db[:cached_standards].bulk_write(batch, :ordered => false)
      rescue
        # Retry one at a time so that a single bad standard doesn't take the
        # whole batch down with it, and so the failing write gets printed.
        batch.each{|write|
          begin
            $db[:cached_standards].bulk_write([write], :ordered => false)
          rescue
            pp write
            raise
          end
        }
      end
    }
  end

  def self.generate(standardSet)
    writes = []
    self.each_write_batch(standardSet){|batch| writes.concat(batch) }
    return nil if writes.empty?
    writes
  end

  def self.each_write_batch(standardSet, batch_size = BATCH_SIZE)
    p "Caching #{standardSet["jurisdiction"]["title"]} #{standardSet["subject"]} #{standardSet["title"]}"
    return if standardSet["standards"].nil? || standardSet["standards"].empty?

    standards = StandardHierarchy.sort_standards(standardSet["standards"])
    ancestors_by_index = StandardHierarchy.ancestors_for(standards)

    document_id      = standardSet["document"] ? standardSet["document"]["id"] : nil
    jurisdiction_id  = standardSet["jurisdiction"] ? standardSet["jurisdiction"]["id"] : nil
    jurisdiction_title = standardSet["jurisdiction"] ? standardSet["jurisdiction"]["title"] : nil

    batch = []
    standards.each_with_index{|s, i|
      batch.push({
        :replace_one => {
          :filter => {_id: s["id"]},
          :replacement => {
            asnIdentifier:   s["asnIdentifier"],
            standardSetId:   standardSet["_id"],
            standardSetTitle: standardSet["title"],
            standardDocumentId: document_id,
            jurisdictionId:  jurisdiction_id,
            jurisdictionTitle: jurisdiction_title,
            subject:         standardSet["subject"],
            educationLevels: standardSet["educationLevels"],
            position:        s["position"],
            depth:           s["depth"],
            statementNotation: s["statementNotation"],
            altStatementNotation: s["altStatementNotation"],
            statementLabel:  s["statementLabel"],
            listId:          s["listId"],
            description:     s["description"],
            comments:        s["comments"],
            ancestorIds:     ancestors_by_index[i].map{|a| a["id"]},
            createdAt:       standardSet["createdAt"],
            updatedAt:       standardSet["updatedAt"]
          },
          :upsert => true
        }
      })

      if batch.length >= batch_size
        yield batch
        batch = []
      end
    }

    yield batch unless batch.empty?
  end

end
