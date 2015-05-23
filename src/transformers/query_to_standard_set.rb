require 'mongo'
require 'securerandom'
require 'pp'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


class QueryToStandardSet

  def self.generate(standardsHash, query)
    client = $db
    cached_standards = client[:cached_standards]


    # Find standards
    # ==============
    time_start = Time.now
    standards     = query["children"].reduce([], &self.gather_standards.call(standardsHash, query["educationLevels"]) )
    standardsHash = standards.compact.reduce({}) {|memo, standard| memo.merge({standard["asnIdentifier"] => standard})}


    # Process Standards
    # =================
    processed_standards = standards
      .map(&self.set_ancestors.call(query["children"], standardsHash)) # set the ancestors as an array
      .map(&self.set_guid.call(cached_standards, query)) # set a guid, looking  to see if there's already a standard with a GUID
      .reduce([], &self.make_linked_list) # assign next_child ids
      .reduce({}, &self.list_to_hash)

    time_end = Time.now

    {
      title:     query["title"],
      standards: processed_standards,
      timeTook:  (time_end - time_start)*1000
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
        p matched
        raise "More than one standard matched an ID"
      when ->(m) {m.length == 0}
        standard.merge({"id" =>  SecureRandom.uuid().gsub('-', '').upcase})
      end

    }.curry
  end


  def self.make_linked_list
    lambda{|memo, standard|
      if memo.last
        memo.last["nextStandard"] = standard["id"]
      else
        standard["firstStandard"] = true
      end
      memo.push(standard)
    }.curry
  end

  def self.list_to_hash
    lambda{|memo, standard|
      memo[standard["id"]] = standard
      memo
    }
  end


end
