class StandardHierarchy

  def self.add_ancestor_ids(standardsHash)
    return {} unless standardsHash
    standards = self.sort_standards(standardsHash)
    ancestors_by_index = self.ancestors_for(standards)

    standards.each_with_index.reduce({}){|acc, (standard, i)|
      ancestors = ancestors_by_index[i]
      parent = ancestors.find{|a| a["depth"] == standard["depth"] - 1}

      acc[standard["id"]] = standard.merge({
        ancestorIds: ancestors.map{|a| a["id"]},
        parentId: parent ? parent["id"] : nil
      })
      acc
    }
  end

  # Standards are ordered from the bottom of the document to the top because
  # (for whatever reason) it's easier to think about the ancestor algorithm
  # when moving up (instead of down) a tree.
  def self.sort_standards(standardsHash)
    standardsHash.values.reject{|s| s == ""}.sort_by{|s| s["position"].to_i}.reverse
  end

  # Returns an array parallel to `standards` (which must be ordered by
  # descending position) where each entry is that standard's ancestors, nearest
  # ancestor first.
  #
  # A standard's ancestors are the standards before it in the document whose
  # depth keeps decreasing, up to and including the root. Walking backwards
  # through the array for every standard is O(n^2) -- and allocates a copy of
  # the remaining standards each time -- so instead we walk the document from
  # the top down once, keeping the chain of still-open ancestors on a stack.
  def self.ancestors_for(standards)
    ancestors_by_index = Array.new(standards.length)
    open_ancestors = []

    (standards.length - 1).downto(0){|i|
      standard = standards[i]
      depth = self.depth_of(standard)

      open_ancestors.pop while !open_ancestors.empty? && self.depth_of(open_ancestors.last) >= depth

      # Root standards don't have ancestors
      ancestors_by_index[i] = depth == 0 ? [] : open_ancestors.reverse
      open_ancestors.push(standard) unless standard.nil?
    }

    ancestors_by_index
  end

  def self.depth_of(standard)
    return 0 if standard.nil? || standard["depth"].nil?
    standard["depth"]
  end

end
