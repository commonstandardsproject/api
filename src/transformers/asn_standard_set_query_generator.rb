require 'pp'

class ASNStandardSetQueryGenerator

  def self.generate(asnDocumentHash)
    # Get standards and set defaults
    standards = asnDocumentHash["standards"].values.map{|doc| doc["educationLevel"] ||= []; doc}

    ["PK", "K", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
      .map{|level| { "educationLevels" => [level] } }
      .map(&self.assign_standard_ids.call(standards))  # Add standard ids to each group
      .reject{|group| group["standardIds"].empty? || group["standardIds"].nil?} # Reject if there are no standards for the grade level
      .reduce([], &self.group_with_same_standards) # E.g. If Grade 6, 7, 8 have the same standard ids, group them
      .map{|s| s.select{|k| k != "standardIds"}}
      .map(&self.assign_title) # E.g. "Grade 6, 7, 8 Math"
      .map(&self.assign_query.call(asnDocumentHash)) # E.g. educationLevels => [06, 07, 08]
  end



  # =========================
  # Private(ish) Methods
  # To Ruby, calling these from another class method requires them to be public
  # but, in pratice, they're only called from this class.
  # =========================


  def self.assign_standard_ids
    -> (standards, group){
      group.merge({
        "standardIds" => standards.select{|s| s["educationLevel"].include? group["educationLevels"].first}
                                  .map{|s| s["asnIdentifier"]}
      })
    }.curry
  end


  def self.group_with_same_standards
    lambda{|memo, group|
      group_with_same_standards = memo.detect do |comparision_group|
        comparision_group["standardIds"] == group["standardIds"]
      end
      if group_with_same_standards
        memo = memo - [group_with_same_standards] # remove the group
        group["educationLevels"].concat(group_with_same_standards["educationLevels"])
      end
      memo.push(group)
    }
  end


  def self.assign_title
    -> (group) {
      pluralized_grade    = (group["educationLevels"].length > 1 ? "Grades" : "Grade")
      # Sort, remove leading 0 and join
      grade_levels_string = group["educationLevels"].sort.map(&->(s){s.gsub(/^0*/,"")}).join(', ')

      group.merge({ "title" => pluralized_grade + " " + grade_levels_string})
    }
  end


  def self.assign_query
    -> (asnDocumentHash, group){
      group.merge({
        "query" => {
          "educationLevels" => group["educationLevels"].sort,
          "rootIds"         => asnDocumentHash["document"]["children"]
        }
      })
    }.curry
  end

end
