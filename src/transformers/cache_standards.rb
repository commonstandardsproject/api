require 'mongo'
require 'securerandom'
require 'pp'
require 'active_support/core_ext/hash/slice'


logger = Logger.new(STDOUT)
logger.level = Logger::WARN
Mongo::Logger.logger = logger
$db = $db || Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'standards')


class CacheStandardSet
  def self.cache(standardSet)
    standards = standardSet["standards"].values.sort_by{|s| s["position"]}.reverse
    collection = standards.each_with_index.map{|standard, i|
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
        ancestorDescriptions: ancestors.map{|a| a["description"]},
        educationLevels: standardSet["educationLevels"],
        subject: standardSet["subject"],
        standardSet: {
          title: standardSet["title"],
          id: standardSet["_id"]
        },
        jurisdiction: standardSet["jurisdiction"],
        _tags: [ancestor_ids, standardSet["_id"], standardSet["jurisdiction"]["id"], standardSet["educationLevels"]].flatten
      })
    }
  end

end
