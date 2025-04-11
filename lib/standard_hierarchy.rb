class StandardHierarchy

  def self.add_ancestor_ids(standardsHash)
    return {} unless standardsHash
    standards = standardsHash.values.sort_by{|s| s["position"]}.reverse

    standards
      .each_with_index
      .map{|standard, i|
        ancestors = self.find_ancestors(standards, standard, i)
        parent = ancestors.find{|a| a["depth"] == standard["depth"] - 1}

        standard.merge({
          ancestorIds: ancestors.map{|a| a["id"]},
          parentId: parent ? parent["id"] : nil
        })
      }.reduce({}){|acc, standard|
        acc[standard["id"]] = standard
        acc
      }
  end


  def self.find_ancestors(standards, standard, i)
    # If it's a root standard, it doesn't have ancestors
    if standard.nil? || standard["depth"] == 0 || standard["depth"] == nil
      return []
    end
    last_standard = standard
    standards[i+1..-1].inject([]){ |acc, ss|

      # If it's a root standard, we're done here and can break
      if ss["depth"] == 0 || ss["depth"] == nil
        acc.push(ss)
        break acc

      # If the standard is a level above the last standard we pushed onto the ancestor array,
      # we add it to the ancestors array and set it to be the new last_standard
      elsif ss["depth"] < last_standard["depth"]
        last_standard = ss
        next acc.push(ss)

      # Otherwise, we'll just call next
      else
        next acc
      end
    }
  end

end
