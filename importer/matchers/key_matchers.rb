require_relative "jurisdiction_matchers"
require_relative "ngss_matchers"

KEY_MATCHERS = {

  # "http://xmlns.com/foaf/0.1/primaryTopic":[
  #   {
  #     "value":"http://asn.jesandco.org/resources/D10003FB",
  #     "type":"uri"
  #   }
  # ],
  "http://xmlns.com/foaf/0.1/primaryTopic" => lambda {|key, value|
    new_value = value.first["value"].match(/http\:\/\/asn\.(?:desire2learn\.com|jesandco\.org)\/resources\/(.+)/).to_a.last
    {primaryTopic: new_value}
  },





  # "http://purl.org/dc/terms/rightsHolder":[
  #   {
  #     "value":"Desire2Learn Incorporated",
  #     "type":"literal",
  #     "datatype":"http://www.w3.org/2001/XMLSchema#string"
  #   }
  # ],
  #
  "http://purl.org/dc/terms/rightsHolder" => lambda{|key, value|
    new_value = value.first["value"]
    {rightsHolder: new_value}
  },






  # "http://purl.org/dc/terms/created":[
  #   {
  #     "value":"2011-03-08T13:57:24-05:00",
  #     "type":"literal",
  #     "datatype":"http://www.w3.org/2001/XMLSchema#date"
  #   }
  # ],

  "http://purl.org/dc/terms/created" => lambda {|key, value|
    {created: value.first["value"]}
  },



  # "http://purl.org/ASN/schema/core/derivedFrom" : [
  #   { "value" : "http://asn.jesandco.org/resources/S2454620", "type" : "uri" }
  # ],

  "http://purl.org/ASN/schema/core/derivedFrom"  => lambda{|key, value|
    { derivedFrom: value.first["value"] }
  },



  # "http://purl.org/dc/terms/creator" : [
  #   { "value" : "http://purl.org/ASN/scheme/ASNJurisdiction/OR", "type" : "uri" }
  # ],

  "http://purl.org/dc/terms/creator" => lambda {|key, value|
    jurisdictionUrl = value.first["value"].match(/(http\:\/\/purl\.org\/ASN\/scheme\/ASNJurisdiction\/.+)/).to_a.first
    {
      creatorUrl: jurisdictionUrl,
      creatorId:  JURISDICTION_MATCHERS[jurisdictionUrl]["id"],
      creator:    JURISDICTION_MATCHERS[jurisdictionUrl]["title"]
    }
  },



  # "http://purl.org/dc/elements/1.1/creator" : [
  #   { "value" : "JES & Co.", "type" : "literal", "datatype" : "http://www.w3.org/2001/XMLSchema#string" }
  # ],

  "http://purl.org/dc/elements/1.1/creator" => lambda{|key, value|
    {
      creator: value.first["value"]
    }
  },


  # "http://purl.org/dc/terms/modified":[
  #   {
  #     "value":"2012-12-06T14:07:02-05:00",
  #     "type":"literal",
  #     "datatype":"http://www.w3.org/2001/XMLSchema#date"
  #   }
  # ],

  "http://purl.org/dc/terms/modified" => lambda{|key, value|
    {modified: value.first["value"]}
  },





  # "http://creativecommons.org/ns#license":[
  #   {
  #     "value":"http://creativecommons.org/licenses/by/3.0/us/",
  #     "type":"uri"
  #   }
  # ],
  #

  "http://creativecommons.org/ns#license" => lambda{|key, value|
    {
      license: "CC BY 3.0 US",
      licenseURL: value.first["value"]
    }
  },



  # "http://purl.org/dc/terms/license"=> [
  #   {
  #     "value"=> "http://www.nationalarchives.gov.uk/doc/open-government-licence/",
  #     "type"=>"uri"
  #   }
  # ],

  "http://purl.org/dc/terms/license"=> lambda{|key, value|
    {
      license: "Open Government Licence v3.0",
      licenseURL: value.first["value"]
    }
  },



  # "http://creativecommons.org/ns#attributionURL":[
  #   {
  #     "value":"http://creativecommons.org/licenses/by/3.0/us/",
  #     "type":"uri"
  #   }
  # ],
  #

  "http://creativecommons.org/ns#attributionURL" => lambda{|key, value|
    { attributionURL: value.first["value"] }
  },





  # "http://creativecommons.org/ns#attributionName":[
  #   {
  #     "value":"Desire2Learn Incorporated",
  #     "type":"literal",
  #     "datatype":"http://www.w3.org/2001/XMLSchema#string"
  #   }
  # ],

  "http://creativecommons.org/ns#attributionName" => lambda{|key, value|
      { attributionName: value.first["value"] }
   },



  # "http://purl.org/ASN/schema/core/exportVersion":[
  #   {
  #     "value":"http://purl.org/ASN/scheme/ASNExport/3.1.0",
  #     "type":"uri"
  #   }
  # ]

  "http://purl.org/ASN/schema/core/exportVersion" => lambda{|key, value|
      { exportVersion: value.first["value"] }
   },



  #
  # "http://www.w3.org/1999/02/22-rdf-syntax-ns#type":[
  #   {
  #     "value":"http://purl.org/ASN/schema/core/StandardDocument",
  #     "type":"uri"
  #   }
  # ],

  "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" => lambda{|key, value|
      { type: value.first["value"].match(/http\:\/\/purl.org\/ASN\/schema\/core\/(.+)/).to_a.last }
   },




  # "http://purl.org/ASN/schema/core/jurisdiction":[
  #   {
  #     "value":"http://purl.org/ASN/scheme/ASNJurisdiction/CCSS",
  #     "type":"uri"
  #   }
  # ],

  "http://purl.org/ASN/schema/core/jurisdiction" => lambda{|key, value|
      {
        jurisdiction:      value.first["value"],
        jurisdictionId:    JURISDICTION_MATCHERS[value.first["value"]][:id],
        jurisdictionTitle: JURISDICTION_MATCHERS[value.first["value"]][:title]
      }
   },



  # "http://purl.org/dc/elements/1.1/title":[
  #   {
  #     "value":"Common Core State Standards for Mathematics",
  #     "type":"literal",
  #     "lang":"en-US"
  #   }
  # ],

  "http://purl.org/dc/elements/1.1/title" => lambda{|key, value|
      { title: value.first["value"] }
   },




  # "http://purl.org/dc/terms/description":[
  #   {
  #     "value":"These Standards define what students should understand and be able to do in their study of mathematics. Asking a student to understand something means asking a teacher to assess whether the student has understood it. But what does mathematical understanding look like? One hallmark of mathematical understanding is the ability to justify, in a way appropriate to the student's mathematical maturity, why a particular mathematical statement is true or where a mathematical rule comes from. There is a world of difference between a student who can summon a mnemonic device to expand a product such as (a + b)(x + y) and a student who can explain where the mnemonic comes from. The student who can explain the rule understands the mathematics, and may have a better chance to succeed at a less familiar task such as expanding (a + b + c)(x + y). Mathematical understanding and procedural skill are equally important, and both are assessable using mathematical tasks of sufficient richness.",
  #     "type":"literal",
  #     "lang":"en-US"
  #   }
  # ],

  "http://purl.org/dc/terms/description" => lambda{|key, value|
      { description: value.first["value"] }
   },






  # "http://purl.org/dc/terms/source":[
  #   {
  #     "value":"http://www.corestandards.org/assets/CCSSI_Math%20Standards.pdf",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/dc/terms/source" => lambda{|key, value|
      { source: value.first["value"] }
   },



  # "http://purl.org/ASN/schema/core/publicationStatus":[
  #   {
  #     "value":"http://purl.org/ASN/scheme/ASNPublicationStatus/Published",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/publicationStatus" => lambda{|key, value|
      {
        publicationStatus: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/scheme\/ASNPublicationStatus\/(.+)/).to_a.last
      }
   },





  # "http://purl.org/ASN/schema/core/repositoryDate":[
  #   {
  #     "value":"2011-03-08",
  #     "type":"literal",
  #     "datatype":"http://purl.org/dc/terms/W3CDTF"
  #   }
  # ],

  "http://purl.org/ASN/schema/core/repositoryDate" => lambda{|key, value|
      {
        repositoryDate: value.first["value"]
      }
   },


  # "http://purl.org/dc/terms/dateCopyright":[
  #   {
  #     "value":"2010",
  #     "type":"literal",
  #     "datatype":"http://purl.org/dc/terms/W3CDTF"
  #   }
  # ],
  "http://purl.org/dc/terms/dateCopyright" => lambda{|key, value|
      {
        dateCopyright: value.first["value"]
      }
   },

  # "http://purl.org/dc/terms/valid":[
  #   {
  #     "value":"2010",
  #     "type":"literal",
  #     "datatype":"http://purl.org/dc/terms/W3CDTF"
  #   }
  # ],

  "http://purl.org/dc/terms/valid" => lambda{|key, value|
      {
        valid: value.first["value"]
      }
   },





  # "http://purl.org/dc/terms/tableOfContents":[
  #   {
  #     "value":"http://asn.jesandco.org/resources/D10003FB/manifest.json",
  #     "type":"uri"
  #   }
  # ],
  #
  "http://purl.org/dc/terms/tableOfContents" => lambda{|key, value|
      {
        tableOfContents: value.first["value"]
      }
   },




  # "http://purl.org/dc/terms/subject":[
  #   {
  #     "value":"http://purl.org/ASN/scheme/ASNTopic/math",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/dc/terms/subject" => lambda{|key, value|
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
   },

  #  "http://purl.org/ASN/schema/core/conceptTerm" : [
  #    { "value" : "http://purl.org/ASN/scheme/NGSSTopic/7", "type" : "uri" }
  #  ],

  "http://purl.org/ASN/schema/core/conceptTerm" => lambda{|key, value|
    { conceptTerm: NGSS_TOPICS_MATCHERS[value.first["value"]] }
  },

  #
  #  "http://purl.org/ASN/schema/core/localSubject" : [
  #    { "value" : "Music", "type" : "literal", "lang" : "en-US" }
  #  ],

  "http://purl.org/ASN/schema/core/localSubject" => lambda{|key, value|
    {
      localSubject: value.first["value"]
    }
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
  "http://purl.org/dc/terms/educationLevel" => lambda{|key, value|
      education_levels = value
        .map{|v| v["value"]}
        .map{|v| v.match(/http\:\/\/purl.org\/ASN\/scheme\/ASNEducationLevel(_CAN-BC)?\/(.+)/).to_a.last}
        .map{|level|
          if level.to_i && level.to_i < 10 && level.to_i > 0
            "0" + level
          else
            level
          end
        }

      { educationLevels: education_levels }
   },



  # "http://purl.org/dc/terms/language":[
  #   {
  #     "value":"http://id.loc.gov/vocabulary/iso639-2/eng",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/dc/terms/language" => lambda{|key, value|
    language_map = {
      "http://id.loc.gov/vocabulary/iso639-2/eng" => "English"
    }
    { language: language_map[value.first["value"]] }
   },


  #  "http://www.w3.org/2000/01/rdf-schema#seeAlso" : [
  #    { "value" : "http://goo.gl/GOzGS", "type" : "uri" }
  #  ],

  "http://www.w3.org/2000/01/rdf-schema#seeAlso" => lambda{|key, value|
    { seeAlso: value.first["value"] }
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
  "http://www.loc.gov/loc.terms/relators/aut" => lambda{|key, value|
      {
        author: value.map{|v| v["value"]}
      }
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
  "http://purl.org/dc/elements/1.1/publisher" => lambda{|key, value|
      {
        publisher: value.map{|v| v["value"]}
      }
   },


  #  "http://www.w3.org/2004/02/skos/core#note" : [
  #    { "value" : "Free print copies of the National Standards book will be available through Jump$tart national partner: Publications.USA.Gov very soon. (In the meantime, Publications.USA.Gov still has copies of the third edition available, free.) Enter search text: National Standards in K-12 Personal Finance Education.", "type" : "literal", "lang" : "en-US" }
  #  ],

  "http://www.w3.org/2004/02/skos/core#note" => lambda{|key, value|
    {
      note: value.first["value"]
    }
  },


  # "http://purl.org/dc/terms/rights":[
  #   {
  #     "value":"© Copyright 2010. National Governors Association Center for Best Practices and Council of Chief State School Officers. All rights reserved.",
  #     "type":"literal",
  #     "lang":"en-US"
  #   }
  # ],
  "http://purl.org/dc/terms/rights" => lambda{|key, value|
      {
        rights: value.map{|v| v["value"]}
      }
   },



  # "http://purl.org/ASN/schema/core/identifier":[
  #   {
  #     "value":"http://purl.org/ASN/resources/D10003FB",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/identifier" => lambda{|key, value|
      {
        asnIdentifier: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/resources\/(.+)/).to_a.last
      }
   },


  # "http://purl.org/gem/qualifiers/hasChild":[
  #   {
  #     "value":"http://asn.jesandco.org/resources/S2366905",
  #     "type":"uri"
  #   },
  #
  "http://purl.org/gem/qualifiers/hasChild" => lambda{|key, value|
      {
        children: value.map{|v| v["value"].match(/http\:\/\/asn\.(?:desire2learn\.com|jesandco\.org)\/resources\/(.+)/).to_a.last }
      }
   },



  #
  # "http://purl.org/dc/terms/isPartOf":[
  #   {
  #     "value":"http://asn.jesandco.org/resources/D10003FB",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/dc/terms/isPartOf" => lambda{|key, value|
      {
        isPartOf: value.first["value"].match(/http\:\/\/asn\.(?:desire2learn\.com|jesandco\.org)\/resources\/(.+)/).to_a.last
      }
   },




  # "http://purl.org/gem/qualifiers/isChildOf":[
  #   {
  #     "value":"http://asn.jesandco.org/resources/S114340E",
  #     "type":"uri"
  #   }
  # ]
  "http://purl.org/gem/qualifiers/isChildOf" => lambda{|key, value|
      {
        isChildOf: value.first["value"].match(/http\:\/\/asn\.(?:desire2learn\.com|jesandco\.org)\/resources\/(.+)/).to_a.last
      }
   },


  # "http://purl.org/ASN/schema/core/authorityStatus":[
  #   {
  #     "value":"http://purl.org/ASN/scheme/ASNAuthorityStatus/Original",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/authorityStatus" => lambda{|key, value|
      {
        authorityStatus: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/scheme\/ASNAuthorityStatus\/(.+)/).to_a.last
      }
   },



  # "http://purl.org/ASN/schema/core/indexingStatus":[
  #   {
  #     "value":"http://purl.org/ASN/scheme/ASNIndexingStatus/Yes",
  #     "type":"uri"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/indexingStatus" => lambda{|key, value|
      {
        indexingStatus: value.first["value"].match(/http\:\/\/purl\.org\/ASN\/scheme\/ASNIndexingStatus\/(.+)/).to_a.last
      }
   },




  # "http://purl.org/ASN/schema/core/statementNotation":[
  #   {
  #     "value":"CCSS.Math.Practice.MP1",
  #     "type":"literal"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/statementNotation" => lambda{|key, value|
      {
        statementNotation: value.first["value"],
      }
   },


  # "http://purl.org/ASN/schema/core/listID":[
  #   {
  #     "value":"1.",
  #     "type":"literal"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/listID" => lambda{|key, value|
      {
        # listId: value.first["value"].gsub(/\.$/, '').gsub(/\)$/, '').gsub(/^\(/, '').gsub(/:$/, ''),
        listId: value.first["value"]
      }
   },


  # "http://purl.org/ASN/schema/core/altStatementNotation":[
  #   {
  #     "value":"MP.1",
  #     "type":"literal"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/altStatementNotation" => lambda{|key, value|
      {
        altStatementNotation: value.first["value"]
      }
   },



  # "http://purl.org/ASN/schema/core/statementLabel":[
  #   {
  #     "value":"Standard",
  #     "type":"literal",
  #     "lang":"en-US"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/statementLabel" => lambda{|key, value|
      {
        statementLabel: value.first["value"]
      }
   },

  #  "http://purl.org/ASN/schema/core/conceptKeyword" : [
  #    { "value" : "Optics", "type" : "literal", "lang" : "en-GB" }
  #  ],

  "http://purl.org/ASN/schema/core/conceptKeyword" => lambda{|key, value|
    { conceptKeyword: value.first["value"]}
  },

  # "http://purl.org/ASN/schema/core/comment":[
  #   {
  #     "value":"Mathematically proficient students start by explaining to themselves the meaning of a problem and looking for entry points to its solution. They analyze givens, constraints, relationships, and goals. They make conjectures about the form and meaning of the solution and plan a solution pathway rather than simply jumping into a solution attempt. They consider analogous problems, and try special cases and simpler forms of the original problem in order to gain insight into its solution. They monitor and evaluate their progress and change course if necessary. Older students might, depending on the context of the problem, transform algebraic expressions or change the viewing window on their graphing calculator to get the information they need. Mathematically proficient students can explain correspondences between equations, verbal descriptions, tables, and graphs or draw diagrams of important features and relationships, graph data, and search for regularity or trends. Younger students might rely on using concrete objects or pictures to help conceptualize and solve a problem. Mathematically proficient students check their answers to problems using a different method, and they continually ask themselves, \"Does this make sense?\" They can understand the approaches of others to solving complex problems and identify correspondences between different approaches.",
  #     "type":"literal",
  #     "lang":"en-US"
  #   }
  # ],
  "http://purl.org/ASN/schema/core/comment" => lambda{|key, value|
      {
        comments: value.map{|v| v["value"]}
      }
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
  "http://www.w3.org/2004/02/skos/core#exactMatch" => lambda{|key, value|
      {
        exactMatch: value.map{|v| v["value"].gsub('urn:guid:', '')}
      }
  },


  # "http://purl.org/ASN/schema/core/comprisedOf" : [
  #   { "value" : "http://asn.jesandco.org/resources/S2470857", "type" : "uri" },
  #   { "value" : "http://asn.jesandco.org/resources/S2470868", "type" : "uri" },
  #   { "value" : "http://asn.jesandco.org/resources/S2470846", "type" : "uri" }
  # ],
  "http://purl.org/ASN/schema/core/comprisedOf" => lambda{|key, value|
    { comprisedOf: value.map{|el| el["value"]} }
  },

  # "http://purl.org/ASN/schema/core/alignTo" : [
  #   { "value" : "http://corestandards.org/ELA-Literacy/RI/3/1", "type" : "uri" },
  #   { "value" : "http://corestandards.org/ELA-Literacy/RI/3/2", "type" : "uri" },
  #   { "value" : "http://corestandards.org/ELA-Literacy/RI/3/3", "type" : "uri" },
  #   { "value" : "http://corestandards.org/ELA-Literacy/W/3/2", "type" : "uri" },
  #   { "value" : "http://corestandards.org/ELA-Literacy/SL/3/4", "type" : "uri" },
  #   { "value" : "http://corestandards.org/Math/Content/3/MD/B/3", "type" : "uri" }
  # ],

  "http://purl.org/ASN/schema/core/alignTo" => lambda{|key, value|
    { alignTo: value.map{|el| el["value"]} }
  },

  # "http://purl.org/dc/terms/isVersionOf" : [
  #   { "value" : "http://corestandards.org/ELA-Literacy/RH/6-8/7", "type" : "uri" }
  # ],

  "http://purl.org/dc/terms/isVersionOf"  => lambda{|key, value|
    { isVersionOf: value.first["value"] }
  }


}
