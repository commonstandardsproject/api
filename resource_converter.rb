class ResourceConverter

  def self.convert(hash)
    # Tuple has the form [key, value]
    new_hash = hash.reduce({}) do |memo, tuple|

      matcher = match_key(tuple[0])

      if !matcher.nil? && !matcher.empty?
        matcher[:replace].call(tuple[0], tuple[1]).each do |ret_key,ret_value|
          memo[ret_key.to_s] = ret_value
        end
      else
        memo[tuple[0]] = tuple[1]
      end

      memo
    end

    return new_hash
  end

  def self.match_key(key)
    match = KEY_MATCHERS.select do |matcher|
      key == matcher[:key_match]
    end.first
    match
  end

  KEY_MATCHERS = [

    # "http://xmlns.com/foaf/0.1/primaryTopic":[
    #   {
    #     "value":"http://asn.jesandco.org/resources/D10003FB",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://xmlns.com/foaf/0.1/primaryTopic",
      replace: Proc.new do |key, value|
        new_value = value.first["value"].match(/http\:\/\/asn\.jesandco\.org\/resources\/(.+)/).to_a.last
        {primaryTopic: new_value}
      end
    },



    # "http://purl.org/dc/terms/rightsHolder":[
    #   {
    #     "value":"Desire2Learn Incorporated",
    #     "type":"literal",
    #     "datatype":"http://www.w3.org/2001/XMLSchema#string"
    #   }
    # ],
    #
    {
      key_match: "http://purl.org/dc/terms/rightsHolder",
      replace: Proc.new do |key, value|
        new_value = value.first["value"]
        {rightsHolder: new_value}
      end
    },






    # "http://purl.org/dc/terms/created":[
    #   {
    #     "value":"2011-03-08T13:57:24-05:00",
    #     "type":"literal",
    #     "datatype":"http://www.w3.org/2001/XMLSchema#date"
    #   }
    # ],

    {
      key_match: "http://purl.org/dc/terms/created",
      replace: Proc.new do |key, value|
        {created: value.first["value"]}
      end
    },






    # "http://purl.org/dc/terms/modified":[
    #   {
    #     "value":"2012-12-06T14:07:02-05:00",
    #     "type":"literal",
    #     "datatype":"http://www.w3.org/2001/XMLSchema#date"
    #   }
    # ],

    {
      key_match: "http://purl.org/dc/terms/modified",
      replace: Proc.new do |key, value|
        {modified: value.first["value"]}
      end
    },





    # "http://creativecommons.org/ns#license":[
    #   {
    #     "value":"http://creativecommons.org/licenses/by/3.0/us/",
    #     "type":"uri"
    #   }
    # ],
    #

    {
      key_match: "http://creativecommons.org/ns#license",
      replace: Proc.new do |key, value|
        {
          license: "CC BY 3.0 US",
          licenseURL: value.first["value"]
        }
      end
    },





    # "http://creativecommons.org/ns#attributionURL":[
    #   {
    #     "value":"http://creativecommons.org/licenses/by/3.0/us/",
    #     "type":"uri"
    #   }
    # ],
    #

    {
      key_match: "http://creativecommons.org/ns#attributionURL",
      replace: Proc.new do |key, value|
        { attributionURL: value.first["value"] }
      end
    },





    # "http://creativecommons.org/ns#attributionName":[
    #   {
    #     "value":"Desire2Learn Incorporated",
    #     "type":"literal",
    #     "datatype":"http://www.w3.org/2001/XMLSchema#string"
    #   }
    # ],

    {
      key_match: "http://creativecommons.org/ns#attributionName",
      replace: Proc.new do |key, value|
        { attributionName: value.first["value"] }
      end
    },



    # "http://purl.org/ASN/schema/core/exportVersion":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNExport/3.1.0",
    #     "type":"uri"
    #   }
    # ]

    {
      key_match: "http://purl.org/ASN/schema/core/exportVersion",
      replace: Proc.new do |key, value|
        { attributionName: value.first["value"] }
      end
    },



    #
    # "http://www.w3.org/1999/02/22-rdf-syntax-ns#type":[
    #   {
    #     "value":"http://purl.org/ASN/schema/core/StandardDocument",
    #     "type":"uri"
    #   }
    # ],

    {
      key_match: "http://www.w3.org/1999/02/22-rdf-syntax-ns#type",
      replace: Proc.new do |key, value|
        { type: value.first["value"].match(/http\:\/\/purl.org\/ASN\/schema\/core\/(.+)/).to_a.last }
      end
    },




    # "http://purl.org/ASN/schema/core/jurisdiction":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNJurisdiction/CCSS",
    #     "type":"uri"
    #   }
    # ],

    {
      key_match: "http://purl.org/ASN/schema/core/jurisdiction",
      replace: Proc.new do |key, value|
        { jurisdiction: value.first["value"] }
      end
    },



    # "http://purl.org/dc/elements/1.1/title":[
    #   {
    #     "value":"Common Core State Standards for Mathematics",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],

    {
      key_match: "http://purl.org/dc/elements/1.1/title",
      replace: Proc.new do |key, value|
        { title: value.first["value"] }
      end
    },




    # "http://purl.org/dc/terms/description":[
    #   {
    #     "value":"These Standards define what students should understand and be able to do in their study of mathematics. Asking a student to understand something means asking a teacher to assess whether the student has understood it. But what does mathematical understanding look like? One hallmark of mathematical understanding is the ability to justify, in a way appropriate to the student's mathematical maturity, why a particular mathematical statement is true or where a mathematical rule comes from. There is a world of difference between a student who can summon a mnemonic device to expand a product such as (a + b)(x + y) and a student who can explain where the mnemonic comes from. The student who can explain the rule understands the mathematics, and may have a better chance to succeed at a less familiar task such as expanding (a + b + c)(x + y). Mathematical understanding and procedural skill are equally important, and both are assessable using mathematical tasks of sufficient richness.",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],

    {
      key_match: "http://purl.org/dc/terms/description",
      replace: Proc.new do |key, value|
        { description: value.first["value"] }
      end
    },






    # "http://purl.org/dc/terms/source":[
    #   {
    #     "value":"http://www.corestandards.org/assets/CCSSI_Math%20Standards.pdf",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/terms/source",
      replace: Proc.new do |key, value|
        { source: value.first["value"] }
      end
    },



    # "http://purl.org/ASN/schema/core/publicationStatus":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNPublicationStatus/Published",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/publicationStatus",
      replace: Proc.new do |key, value|
        {
          publicationStatus: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/scheme\/ASNPublicationStatus\/(.+)/).to_a.last
        }
      end
    },





    # "http://purl.org/ASN/schema/core/repositoryDate":[
    #   {
    #     "value":"2011-03-08",
    #     "type":"literal",
    #     "datatype":"http://purl.org/dc/terms/W3CDTF"
    #   }
    # ],

    {
      key_match: "http://purl.org/ASN/schema/core/repositoryDate",
      replace: Proc.new do |key, value|
        {
          repositoryDate: value.first["value"]
        }
      end
    },


    # "http://purl.org/dc/terms/dateCopyright":[
    #   {
    #     "value":"2010",
    #     "type":"literal",
    #     "datatype":"http://purl.org/dc/terms/W3CDTF"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/terms/dateCopyright",
      replace: Proc.new do |key, value|
        {
          dateCopyright: value.first["value"]
        }
      end
    },

    # "http://purl.org/dc/terms/valid":[
    #   {
    #     "value":"2010",
    #     "type":"literal",
    #     "datatype":"http://purl.org/dc/terms/W3CDTF"
    #   }
    # ],

    {
      key_match: "http://purl.org/dc/terms/valid",
      replace: Proc.new do |key, value|
        {
          valid: value.first["value"]
        }
      end
    },





    # "http://purl.org/dc/terms/tableOfContents":[
    #   {
    #     "value":"http://asn.jesandco.org/resources/D10003FB/manifest.json",
    #     "type":"uri"
    #   }
    # ],
    #
    {
      key_match: "http://purl.org/dc/terms/tableOfContents",
      replace: Proc.new do |key, value|
        {
          tableOfContents: value.first["value"]
        }
      end
    },




    # "http://purl.org/dc/terms/subject":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNTopic/math",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/terms/subject",
      replace: Proc.new do |key, value|
        subject_map = {
          "http://purl.org/ASN/scheme/ASNTopic/careerEducation" => "Career Education",
          "http://purl.org/ASN/scheme/ASNTopic/english" => "English",
          "http://purl.org/ASN/scheme/ASNTopic/financialLiteracy" => "Financial Literacy",
          "http://purl.org/ASN/scheme/ASNTopic/foreignLanguage" => "Foreign Language",
          "http://purl.org/ASN/scheme/ASNTopic/health" => "Health",
          "http://purl.org/ASN/scheme/ASNTopic/lifeSkills" => "Life Skills",
          "http://purl.org/ASN/scheme/ASNTopic/math" => "Math",
          "http://purl.org/ASN/scheme/ASNTopic/physicalEducation" => "Physical Education",
          "http://purl.org/ASN/scheme/ASNTopic/science" => "Science",
          "http://purl.org/ASN/scheme/ASNTopic/socialStudies" => "Social Studies",
          "http://purl.org/ASN/scheme/ASNTopic/technology" => "Technology",
          "http://purl.org/ASN/scheme/ASNTopic/theArts" => "The Arts"
        }
        {
          subject: subject_map[value.first["value"]]
        }
      end
    },



    # "http://purl.org/dc/terms/educationLevel":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNEducationLevel/K",
    #     "type":"uri"
    #   },
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNEducationLevel/1",
    #     "type":"uri"
    #   },
    # ]
    {
      key_match: "http://purl.org/dc/terms/educationLevel",
      replace: Proc.new do |key, value|
        education_levels = value
          .map{|v| v["value"]}
          .map{|v| v.match(/http\:\/\/purl.org\/ASN\/scheme\/ASNEducationLevel\/(.+)/).to_a.last}
          .map do |level|
            if level.to_i && level.to_i < 10 && level.to_i > 0
              "0" + level
            else
              level
            end
          end
        {
          educationLevel: education_levels
        }
      end
    },



    # "http://purl.org/dc/terms/language":[
    #   {
    #     "value":"http://id.loc.gov/vocabulary/iso639-2/eng",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/terms/language",
      replace: Proc.new do |key, value|
        {
          language: "English" # If ASN starts publishing in other langugaes, this would have to change
        }
      end
    },


    # "http://www.loc.gov/loc.terms/relators/aut":[
    #   {
    #     "value":"National Governors Association Center for Best Practices",
    #     "type":"literal",
    #     "lang":"en-US"
    #   },
    #   {
    #     "value":"Council of Chief State School Officers",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],
    {
      key_match: "http://www.loc.gov/loc.terms/relators/aut",
      replace: Proc.new do |key, value|
        {
          author: value.map{|v| v["value"]}
        }
      end
    },



    # "http://purl.org/dc/elements/1.1/publisher":[
    #   {
    #     "value":"National Governors Association Center for Best Practices",
    #     "type":"literal",
    #     "lang":"en-US"
    #   },
    #   {
    #     "value":"Council of Chief State School Officers, Washington D.C.",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/elements/1.1/publisher",
      replace: Proc.new do |key, value|
        {
          publisher: value.map{|v| v["value"]}
        }
      end
    },


    # "http://purl.org/dc/terms/rights":[
    #   {
    #     "value":"© Copyright 2010. National Governors Association Center for Best Practices and Council of Chief State School Officers. All rights reserved.",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/terms/rights",
      replace: Proc.new do |key, value|
        {
          rights: value.map{|v| v["value"]}
        }
      end
    },



    # "http://purl.org/ASN/schema/core/identifier":[
    #   {
    #     "value":"http://purl.org/ASN/resources/D10003FB",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/identifier",
      replace: Proc.new do |key, value|
        {
          asnIdentifier: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/resources\/(.+)/).to_a.last
        }
      end
    },


    # "http://purl.org/gem/qualifiers/hasChild":[
    #   {
    #     "value":"http://asn.jesandco.org/resources/S2366905",
    #     "type":"uri"
    #   },
    #
    {
      key_match: "http://purl.org/gem/qualifiers/hasChild",
      replace: Proc.new do |key, value|
        {
          children: value.map{|v| v["value"].match(/http\:\/\/asn\.jesandco\.org\/resources\/(.+)/).to_a.last }
        }
      end
    },



    #
    # "http://purl.org/dc/terms/isPartOf":[
    #   {
    #     "value":"http://asn.jesandco.org/resources/D10003FB",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/dc/terms/isPartOf",
      replace: Proc.new do |key, value|
        {
          isPartOf: value.first["value"].match(/http\:\/\/asn\.jesandco\.org\/resources\/(.+)/).to_a.last
        }
      end
    },




    # "http://purl.org/gem/qualifiers/isChildOf":[
    #   {
    #     "value":"http://asn.jesandco.org/resources/S114340E",
    #     "type":"uri"
    #   }
    # ]
    {
      key_match: "http://purl.org/gem/qualifiers/isChildOf",
      replace: Proc.new do |key, value|
        {
          isChildOf: value.first["value"].match(/http\:\/\/asn\.jesandco\.org\/resources\/(.+)/).to_a.last
        }
      end
    },


    # "http://purl.org/ASN/schema/core/authorityStatus":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNAuthorityStatus/Original",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/authorityStatus",
      replace: Proc.new do |key, value|
        {
          authorityStatus: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/scheme\/ASNAuthorityStatus\/(.+)/).to_a.last
        }
      end
    },



    # "http://purl.org/ASN/schema/core/indexingStatus":[
    #   {
    #     "value":"http://purl.org/ASN/scheme/ASNIndexingStatus/Yes",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/indexingStatus",
      replace: Proc.new do |key, value|
        {
          indexingStatus: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/scheme\/ASNIndexingStatus\/(.+)/).to_a.last
        }
      end
    },




    # "http://purl.org/ASN/schema/core/statementNotation":[
    #   {
    #     "value":"CCSS.Math.Practice.MP1",
    #     "type":"literal"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/statementNotation",
      replace: Proc.new do |key, value|
        {
          statementNotation: value.first["value"],
        }
      end
    },


    # "http://purl.org/ASN/schema/core/listID":[
    #   {
    #     "value":"1.",
    #     "type":"literal"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/listID",
      replace: Proc.new do |key, value|
        {
          listID: value.first["value"].gsub('.', '').gsub(')', '').gsub('(', ''),
        }
      end
    },


    # "http://purl.org/ASN/schema/core/altStatementNotation":[
    #   {
    #     "value":"MP.1",
    #     "type":"literal"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/altStatementNotation",
      replace: Proc.new do |key, value|
        {
          altStatementNotation: value.first["value"]
        }
      end
    },



    # "http://purl.org/ASN/schema/core/statementLabel":[
    #   {
    #     "value":"Standard",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/statementLabel",
      replace: Proc.new do |key, value|
        {
          statementLabel: value.first["value"]
        }
      end
    },

    # "http://purl.org/ASN/schema/core/comment":[
    #   {
    #     "value":"Mathematically proficient students start by explaining to themselves the meaning of a problem and looking for entry points to its solution. They analyze givens, constraints, relationships, and goals. They make conjectures about the form and meaning of the solution and plan a solution pathway rather than simply jumping into a solution attempt. They consider analogous problems, and try special cases and simpler forms of the original problem in order to gain insight into its solution. They monitor and evaluate their progress and change course if necessary. Older students might, depending on the context of the problem, transform algebraic expressions or change the viewing window on their graphing calculator to get the information they need. Mathematically proficient students can explain correspondences between equations, verbal descriptions, tables, and graphs or draw diagrams of important features and relationships, graph data, and search for regularity or trends. Younger students might rely on using concrete objects or pictures to help conceptualize and solve a problem. Mathematically proficient students check their answers to problems using a different method, and they continually ask themselves, \"Does this make sense?\" They can understand the approaches of others to solving complex problems and identify correspondences between different approaches.",
    #     "type":"literal",
    #     "lang":"en-US"
    #   }
    # ],
    {
      key_match: "http://purl.org/ASN/schema/core/comment",
      replace: Proc.new do |key, value|
        {
          comments: value.map{|v| v["value"]}
        }
      end
    },



    # "http://www.w3.org/2004/02/skos/core#exactMatch":[
    #   {
    #     "value":"http://corestandards.org/Math/Practice/MP1",
    #     "type":"uri"
    #   },
    #   {
    #     "value":"urn:guid:FBCBB7C696FE475695920CA622B1C854",
    #     "type":"uri"
    #   }
    # ],
    {
      key_match: "http://www.w3.org/2004/02/skos/core#exactMatch",
      replace: Proc.new do |key, value|
        {
          exactMatch: value.map{|v| v["value"].gsub('urn:guid:', '')}
        }
      end
    },
  ]


end
