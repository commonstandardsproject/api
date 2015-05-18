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


    # pp grouped.first[:standards].select{|standard|
    #   standard["statementNotation"].nil?
    # }
    # grouped.each{|group| group[:standards].map{|standard| standard["statementNotation"]}}

    # Find root standards
    # grouped.first[:standards].select{|standard|
    #   parents = grouped.first[:standards].select{|standard2|
    #     standard2["isChildOf"] == standard["asnIdentifier"]
    #   }
    #   parents.length != 0
    # }




    # Find the ancestor tree
    # This finds the children
    # ancestors = grouped.first[:standards].reduce([standard["asnIdentifier"]]){|memo, standard2|
    #   if (memo & [standard2["isChildOf"]]).length > 0
    #     memo.push(standard2["asnIdentifier"])
    #   end
    #   memo
    # }

    # grouped.first[:standards].map{|standard|
    #   ancestor_ids = grouped.first[:standards].reverse.reduce([standard["isChildOf"]]){|memo, standard2|
    #     if (memo & [standard2["asnIdentifier"]]).length > 0
    #       memo.push(standard2["isChildOf"])
    #     end
    #     memo
    #   }
    #
    #   standard["ancestors"] = ancestor_ids - [standard["asnIdentifier"]]
    #   standard
    # }.each{|standard|
    #   if standard["statementNotation"].nil?
    #     p standard
    #   end
    #   p "----------"
    #   pp standard["statementNotation"]
    #   standard["ancestors"] = standard["ancestors"].compact.map{|ancestor|
    #     doc = grouped.first[:standards].detect{|s| s["asnIdentifier"] == ancestor} || {}
    #     doc["statementNotation"]
    #   }
    #   pp standard["ancestors"]
    # }


    standards = grouped[1][:standards]
    hashed = standards.reduce({}){|memo, standard| memo[standard["asnIdentifier"]] = standard; memo}
    standards.reduce([]){|memo, standard|
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
      memo.push(standard)
    }.map{|standard|
      p "#{standard["ancestors"].map{|a| "  "}.join('')}-#{standard["statementNotation"]}"
      # p standard["statementNotation"]

      # pp standard["ancestors"].compact.map{|ancestor|
      #   doc = grouped[1][:standards].detect{|s| s["asnIdentifier"] == ancestor} || {}
      #   doc["statementNotation"]
      # }
    }


    # give each standard
    # - order
    # - nextStandardId

    # Steps
    # lookup the ids.
    # assign new GUIDS
    # convert ancestors to asn_ancestors
    # convert isChildOf to asn_is_child_of


    # Standard Set Needs:
    # - add jurisdiction id
    # - add grade_level tags
    # - add subject tags


    # To find a matching standard set:
    # - Source == Source
    # - GradeLevel == GradeLevel

    # File.write('converted_' + path, Oj.dump(new_hash))
  end

end
