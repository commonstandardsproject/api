require 'securerandom'
require 'set'
require 'pp'
require_relative '../../config/mongo'
require_relative '../matchers/source_to_subject_mapping_grouped'
require 'active_support/core_ext/hash/slice'

# Given a standards set query, this method creates a standards set
class QueryToStandardSet

  def self.all
    $db[:standard_documents].find.batch_size(10).each{|doc|
      queries = doc["standardSetQueries"] || []
      queries.each{|query|
        p "Generating for #{doc["document"]["title"]} #{query["title"]}"
        self.generate(doc, query)
      }
    }
  end

  def self.generate(standardsDoc, query)
    standardsHash = standardsDoc[:standards]
    # Find standards
    # ==============
    time_start = Time.now
    standards     = query["children"].reduce([], &self.gather_standards.call(standardsHash, query["educationLevels"]) )
    # `memo.merge` here would copy the whole hash once per standard, which is
    # O(n^2) in both time and garbage for a document with thousands of them
    standardsHash = standards.each_with_object({}) {|standard, memo|
      memo[standard["asnIdentifier"]] = standard unless standard.nil?
    }


    jurisdictionId = standardsDoc[:document][:jurisdictionId]
    asnId          = standardsDoc[:documentMeta][:primaryTopic]
    queryId        = query["id"]
    id = [jurisdictionId, asnId, queryId].join('_')


    # Process Standards
    # =================
    # Each step of this used to build its own copy of every standard, so a
    # large document held several copies at once. Doing it in a single pass
    # means only the finished (and much smaller) standards stick around.
    children_ids     = Set.new(query["children"] || [])
    set_ancestors_on = self.set_ancestors.call(children_ids, standardsHash)
    set_guid_on      = self.set_guid.call(id, query)
    filter_keys_on   = self.filter_keys
    position         = 0

    processed_standards = standards.uniq.each_with_object({}) {|standard, memo|
      standard = set_ancestors_on.call(standard) # set the ancestors as an array
      standard = set_guid_on.call(standard)      # set a guid, looking to see if there's already a standard with a GUID
      position += 1000
      standard["position"] = position
      standard = filter_keys_on.call(standard)
      memo[standard["id"]] = standard
    }

    time_end = Time.now

    # Return the standards set
    # ========================
    jurisdictionTitle =  $db[:jurisdictions].find({_id: jurisdictionId}).to_a.first[:title]
    {
      "id" => id,
      "jurisdiction": {
        "id"    => jurisdictionId,
        "title" => jurisdictionTitle
      },
      "subject"           => SOURCE_TO_SUBJECT_MAPPINGS_GROUPED[jurisdictionTitle][asnId],
      "normalizedSubject" => standardsDoc["document"]["subject"],
      "document"          => {
        "id"        => standardsDoc["_id"],
        "valid"     => standardsDoc["document"]["valid"],
        "title"     => standardsDoc["document"]["title"],
        "sourceURL" => standardsDoc["document"]["source"],
        "asnIdentifier" => standardsDoc["documentMeta"]["primaryTopic"],
        "publicationStatus" => standardsDoc["document"]["publicationStatus"]
      },
      "license" => {
        "title"          => standardsDoc["documentMeta"]["license"],
        "URL"            => standardsDoc["documentMeta"]["licenseURL"],
        "rightsHolder"    => standardsDoc["documentMeta"]["rightsHolder"],
      },
      "attribution" => {
        "title" => standardsDoc["documentMeta"]["attributionName"],
        "URL"   => standardsDoc["documentMeta"]["attributionURL"]
      },
      "title"           => query["title"],
      "educationLevels" => query["educationLevels"],
      "standards"       => processed_standards,
    }
  end




  # =========================
  # Private(ish) Methods
  # To Ruby, calling these from another class method requires them to be public
  # but, in pratice, they're only called from this class.
  # =========================


  # Also puts the standards in order
  def self.gather_standards
    -> (standardsHash, validEducationLevels, memo, id){
      if (standardsHash[id]["educationLevels"] & validEducationLevels).length > 0
        memo.push(standardsHash[id])
        if standardsHash[id] && standardsHash[id]["children"]
          memo = standardsHash[id]["children"].reduce(memo, &self.gather_standards.call(standardsHash, validEducationLevels))
        end
      end
      memo
    }.curry
  end



  def self.set_ancestors
    get_ancestors = -> (childrenIds, hashed_standards, ancestors, standard){
      ancestor = hashed_standards[standard["isChildOf"]]

      if ancestor
        ancestors.push(ancestor["asnIdentifier"])
      end

      if ancestor && !childrenIds.include?(ancestor["asnIdentifier"])
        get_ancestors.call(childrenIds, hashed_standards, ancestors, ancestor)
      end

      ancestors
    }

    lambda{ |childrenIds, hashed_standards, standard|
      ancestors = get_ancestors.call(childrenIds, hashed_standards, [], standard)
      standard.merge({
        "ancestors" => ancestors,
        "depth"     => ancestors.length
      })
    }.curry
  end




  def self.set_guid
    -> (standard_set_id, query, standard) {
      matched = $db[:cached_standards].find({
        standardSetId: standard_set_id,
        asnIdentifier: standard["asnIdentifier"]
      }).to_a


      case matched
      when ->(m){ m.length == 1}
        standard.merge({"id" => matched[0]["_id"].to_s})
      when ->(m) { m.length > 1 }
        # From tests, these conflicts only appear to be on a few sets:
        # - Nevada Computer and Technology Standards
        # - Arizona Music 9-12
        # - Grade Expectations for Vermont's Framework of Standards and Learning Opportunities"
        #
        # Because these are not core subjects and none of the users in these states
        # has access to the Cc standards tracker at the time of the conversion,
        # we're just going to assign new GUIDs
        #
        # p "===================================================="
        # p "RAISE"
        # p query
        # p matched
        # p "===================================================="
        # raise "More than one standard matched an ID"
        standard.merge({"id" =>  SecureRandom.uuid().gsub('-', '').upcase})
      when ->(m) {m.length == 0}
        standard.merge({"id" =>  SecureRandom.uuid().gsub('-', '').upcase})
      end

    }.curry
  end


  def self.filter_keys
    lambda{|standard|
      standard.slice(
        "id",
        "asnIdentifier",
        "position",
        "depth",
        "statementNotation",
        "altStatementNotation",
        "statementLabel",
        "listId",
        "description",
        "comments",
        "exactMatch"
      )
    }

  end

end
