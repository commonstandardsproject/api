require 'pp'
class ASNStandardSetQueryGenerator

  def self.generate(path)
    hash = Oj.load(File.read(path))

    docs = hash.values()
    # grouped = docs.group_by{|doc| doc["educationLevel"]}

    grade_levels = ["K", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
    grouped = grade_levels.map{|level|
      {
        gradeLevels: [level],
        standards: docs.select{|doc| doc["educationLevel"] ||= []; doc["educationLevel"].include? level}.map{|doc| doc["asnIdentifier"]}
      }
    }.reject{|group|
      group[:standards].nil?
    }.reduce([]){|memo, group|
      group_with_same_standards = memo.detect{|group2|
        group2[:standards] == group[:standards]
      }
      if group_with_same_standards
        memo = memo - [group_with_same_standards] # remove the group
        group[:gradeLevels].concat(group_with_same_standards[:gradeLevels])
      end
      memo.push(group)
    }.map{|group|
      group.merge({
        title: "Grade " + group[:gradeLevels].sort.join(', '),
      })
    }

    # pp grouped.map{|group| group[:title]}

    # ==================
    # Find the standards
    # ==================
    grouped.map!{|group|
      group[:standards] = docs.select{|doc| doc["isPartOf"] == "D10003FB" && (doc["educationLevel"] & group[:gradeLevels]).length > 0}
      group
    }



    # ==================
    # Find the ancestors
    # ==================
    standards = grouped[1][:standards]
    hashed = standards.reduce({}){|memo, standard| memo[standard["asnIdentifier"]] = standard; memo}
    pp standards.map{| standard|
      get_ancestors = lambda {|ancestors, standard|
        ancestor = hashed[standard["isChildOf"]]
        if ancestor
          ancestors.push(standard["asnIdentifier"])
        end

        if ancestor && ancestor["isChildOf"] != "D10003FB"
          get_ancestors.call(ancestors, ancestor)
        end
        ancestors
      }
      standard["ancestors"] = get_ancestors.call([], standard)
      push(standard)
    }

    # standards.reduce([]){|memo, standard|
    #   get_ancestors = lambda {|ancestors, standard|
    #     ancestor = hashed[standard["isChildOf"]]
    #     if ancestor
    #       ancestors.push(standard["asnIdentifier"])
    #     end
    #
    #     if ancestor && ancestor["isChildOf"] != "D10003FB"
    #       get_ancestors.call(ancestors, ancestor)
    #     end
    #     ancestors
    #   }
    #   standard["ancestors"] = get_ancestors.call([], standard)
    #   memo.push(standard)
    # }.map{|standard|
    #   p "#{standard["ancestors"].map{|a| "  "}.join('')}-#{standard["statementNotation"]}"
      # p standard["statementNotation"]

      # pp standard["ancestors"].compact.map{|ancestor|
      #   doc = grouped[1][:standards].detect{|s| s["asnIdentifier"] == ancestor} || {}
      #   doc["statementNotation"]
      # }
    # }
  end

end
