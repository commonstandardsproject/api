require 'mongo'
require 'securerandom'
require 'pp'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger


class QueryToStandardSet

  def self.generate(standardsHash, query)
    client           = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')
    cached_standards = client[:cached_standards]

    standards = standardsHash.select{|key, value| (value["educationLevel"] & query["educationLevels"]).length > 0 }
    rootIds   = query["rootIds"].select{|id| !standards[id].nil? }

    if rootIds.empty?
      return []
    end


    time_start = Time.now
    processed_standards = query["rootIds"]
      .reduce(rootIds, &self.fetch_progeny.call(standards)) # Gather all the progeny -- this is a recursive function
      .map{|id| standards[id]} # get standard
      .compact
      .map(&self.set_ancestors.call(rootIds, standards)) # set the ancestors as an array
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


  def self.fetch_progeny
    -> (standardsHash, ids, id){
      standard = standardsHash[id]
      children = standard && standard["children"] || []
      if standard.nil? || children.empty?
        return ids
      else
        return ids.concat(
          children
        ).concat(
          children.flat_map{|id2| self.fetch_progeny.call(standardsHash, ids, id2)}.flatten.uniq
        ).uniq.compact
      end
    }.curry
  end



  def self.set_ancestors
    get_ancestors = -> (rootIds, hashed_standards, ancestors, standard){
      ancestor = hashed_standards[standard["isChildOf"]]

      if ancestor
        ancestors.push(standard["asnIdentifier"])
      end

      if ancestor && !rootIds.include?(ancestor["isChildOf"])
        get_ancestors.call(rootIds, hashed_standards, ancestors, ancestor)
      end

      ancestors
    }

    lambda{ |rootIds, hashed_standards, standard|
      ancestors = get_ancestors.call(rootIds, hashed_standards, [], standard)
      standard.merge({
        "ancestors" => ancestors,
        "depth" => ancestors.length
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
