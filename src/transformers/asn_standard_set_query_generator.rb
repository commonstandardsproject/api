require 'pp'

# Given a document, this method extracts the standards set queries from the docs
class ASNStandardSetQueryGenerator

  def self.generate(asnDocumentHash)
    # Get standards and set defaults
    standards = asnDocumentHash["standards"].values.map{|doc| doc["educationLevels"] ||= []; doc}

    grade_levels = [
      "Pre-K",
      "K",
      "01",
      "02",
      "03",
      "04",
      "05",
      "06",
      "07",
      "08",
      "09",
      "10",
      "11",
      "12",
      "VocationalTraining",
      "ProfessionalEducation-Development",
      "Graduate",
      "HigherEducation",
      "Undergraduate-UpperDivision",
      "Undergraduate-LowerDivision",
      "AdultEducation",
      "LifeLongLearning",
    ]

    queries = grade_levels
      .map{|level| { "educationLevels" => [level] } }
      .map(&self.assign_standard_ids.call(standards))  # Add standard ids to each group
      .reject{|group| group["standardIds"].empty? || group["standardIds"].nil?} # Reject if there are no standards for the grade level
      .reduce([], &self.group_with_same_standards) # E.g. If Grade 6, 7, 8 have the same standard ids, group them
      .map{|s| s.select{|k| k != "standardIds"}}
      .map(&self.assign_title) # E.g. "Grade 6, 7, 8 Math"
      .map(&self.assign_query.call(asnDocumentHash)) # E.g. educationLevels => [06, 07, 08]

    common_core_exceptions = [
      "High School — Number and Quantity",
      "High School — Algebra",
      "High School — Functions",
      "High School — Geometry",
      "High School — Statistics and Probability<sup>★</sup>"
    ]

    common_core_exceptions.each{|title|
      if standards.map{|s| s["description"]}.include?(title)
        children = standards.find{|s| s["description"] == title}["children"]
        children.unshift(standards.find{|s| s["description"] == "Standards for Mathematical Practice"}["asnIdentifier"])
        queries.push({
          "title" =>           title.gsub("<sup>★</sup>", ""),
          "id" =>              title.gsub("<sup>★</sup>", "").gsub(" ", "-").gsub("—", "").gsub("--", "-").downcase,
          "educationLevels" => ["09", "10", "11", "12"],
          "children" =>        children
        })
      end
    }

    if (queries.map{|q| q["title"]} & common_core_exceptions.map{|t| t.gsub("<sup>★</sup>", "")}).length == common_core_exceptions.length
      # This is pretty hacky to find the high school query
      # where all these standards came from. Should work, though, as this entire
      # thing is only applicable to teh common core
      queries.reject!{|q|
        q["title"] == "Grades 9, 10, 11, 12"
      }
    end

    queries
  end



  # =========================
  # Private(ish) Methods
  # To Ruby, calling these from another class method requires them to be public
  # but, in pratice, they're only called from this class.
  # =========================


  def self.assign_standard_ids
    -> (standards, group){
      group.merge({
        "standardIds" => standards.select{|s| s["educationLevels"].include? group["educationLevels"].first}
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
        group["educationLevels"].concat(group_with_same_standards["educationLevels"]).sort!
      end
      memo.push(group)
    }
  end


  def self.assign_title
    -> (group) {
      # Sort, remove leading 0 and join
      grade_levels_string = group["educationLevels"].sort_by{|level|
        # Super hacky way of getting the sorting correct. There is probably
        # a better way to do this
        if level == "K"
          [2, level]
        elsif level == "Pre-K"
          [1, level]
        elsif level == "VocationalTraining"
          [4, level]
        elsif level.to_i != 0
          [3, level]
        else
          [5, level]
        end
      }.map(&->(s){
        s.gsub(/^0*/,"")
         .gsub("VocationalTraining", "Vocational Training")
         .gsub("ProfessionalEducation-Development", "Professional Education & Further Development")
         .gsub("HigherEducation", "Higher Education")
         .gsub("Undergraduate-UpperDivision", "Four Year College")
         .gsub("Undergraduate-LowerDivision", "Two Year College")
         .gsub("LifeLongLearning", "Life-long Learning")
      }).join(', ')

      if grade_levels_string.match(/(K|1|2|3|4|5|6|7|8|9|10|11|12)/) != nil
        prefix = (group["educationLevels"].length > 1 ? "Grades " : "Grade ")
      else
        prefix = ""
      end

      group.merge({
        "title" => prefix + grade_levels_string,
        "id"    => prefix.gsub(' ', '-').downcase + group["educationLevels"].sort.join('-').downcase
      })
    }
  end


  def self.assign_query
    -> (asnDocumentHash, group){
      group.merge({
        "children" => asnDocumentHash["document"]["children"]
      })
    }.curry
  end

end
