require 'pp';
require 'parallel'
require 'date'
require_relative "../config/mongo";

class CachedStandards

  def self.all
    # sets = $db[:standard_sets].find().batch_size(1000).map{|set|
    #   self.generate(set)
    # }
    sets = $db[:standard_sets].find()
    Parallel.map_with_index(sets){|set, index|
      set = self.generate(set)
      p "Inserting set: #{index+1}"
      next if set.nil? || set.empty?
      begin
        $db[:cached_standards].bulk_write(set, :ordered => false)
      rescue
        pp set
        set.map{|write|
          begin
            $db[:cached_standards].bulk_write([write], :ordered => false)
          rescue
            pp write
            # to rethrow error
            $db[:cached_standards].bulk_write([write], :ordered => false)
          end
        }
      end
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
    standards_hash = StandardHierarchy.add_ancestor_ids(standardSet["standards"])
    standards_hash.values.map{|s|
      {
        :replace_one => {
          :filter => {_id: s["id"]},
          :replacement => {
            asnIdentifier:   s["asnIdentifier"],
            standardSetId:   standardSet["_id"],
            standardDocumentId: standardSet["document"] ? standardSet["document"]["id"] : nil,
            jurisdictionId:  standardSet["jurisdiction"] ? standardSet["jurisdiction"]["id"] : nil,
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
            ancestorIds:     s["ancestorIds"],
            createdAt:       standardSet["createdAt"],
            updatedAt:       standardSet["updatedAt"]
          },
          :upsert => true
        }
      }
    }
  end

end
