require 'mongo'
require 'securerandom'
require 'pp'
require 'active_support/core_ext/hash/slice'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


# Given a standards set query, this method creates a standards set
class QueryToStandardSet

  def self.generate(standardsDoc, query)
    standardsHash = standardsDoc[:standards]
    client = $db
    cached_standards = client[:cached_standards]


    # Find standards
    # ==============
    time_start = Time.now
    standards     = query["children"].reduce([], &self.gather_standards.call(standardsHash, query["educationLevels"]) )
    standardsHash = standards.compact.uniq.reduce({}) {|memo, standard| memo.merge({standard["asnIdentifier"] => standard})}


    # Process Standards
    # =================
    processed_standards = standards
      .map(&self.set_ancestors.call(query["children"], standardsHash)) # set the ancestors as an array
      .uniq
      .map(&self.set_guid.call(cached_standards, query)) # set a guid, looking  to see if there's already a standard with a GUID
      .reduce([], &self.add_position) # assign position
      .map(&self.filter_keys)
      .reduce({}, &self.list_to_hash)

    time_end = Time.now

    jurisdictionId = standardsDoc[:document][:jurisdictionId]
    asnId          = standardsDoc[:documentMeta][:primaryTopic]
    queryId        = query["id"]
    id = [jurisdictionId, asnId, queryId].join('_')

    # Return the standards set
    # ========================
    {
      "id" => id,
      "jurisdiction": {
        "id"    => jurisdictionId,
        "title" => $db[:jurisdictions].find({_id: jurisdictionId}).to_a.first[:title]
      },
      "subject"  => standardsDoc["document"]["subject"],
      "document" => {
        "id"        => standardsDoc["_id"],
        "title"     => standardsDoc["document"]["title"],
        "sourceURL" => standardsDoc["document"]["source"],
      },
      "license" => {
        "title"          => standardsDoc["documentMeta"]["license"],
        "URL"            => standardsDoc["documentMeta"]["licenseURL"],
        "attributionURL" => standardsDoc["documentMeta"]["attributionURL"],
      },
      "rightsHolder"    => standardsDoc["documentMeta"]["rightsHolder"],
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
    -> (cached_standards_collection, query, standard) {
      matched = cached_standards_collection.find({asn_id: standard["asnIdentifier"], grade_levels: {:$in => query["educationLevels"]} }).to_a


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


  def self.add_position
    lambda{|memo, standard|
      standard["position"] = (memo.length + 1) * 1000
      memo.push(standard)
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

  def self.list_to_hash
    lambda{|memo, standard|
      memo[standard["id"]] = standard
      memo
    }
  end


end
