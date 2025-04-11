require 'pp'
require 'dry-validation'
require 'date'
require_relative '../lib/cache_standards'
require_relative '../lib/send_to_algolia'
require_relative "standard"
require_relative "../lib/securerandom"

class StandardSet
  include Virtus.model

  attribute :id, String, default: -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :title, String, default: ""
  attribute :subject, String, default: ""
  attribute :document, Hash, default: {}
  attribute :createdAt, DateTime, default: -> (page, attrs) { Time.now}
  attribute :updatedAt, DateTime
  attribute :version, Integer, default: 1
  attribute :standards, Hash[String => Standard], default: {}
  attribute :standardsCount, Integer, default: 0
  attribute :normalizedSubject, String, default: nil

  class Jurisdiction
    include Virtus.model
    attribute :id, String
    attribute :title, String

    class Validator < ::Dry::Validation::Schema
      key(:id, &:str?)
      key(:title, &:str?)
    end
  end
  attribute :jurisdiction, Jurisdiction, default: -> (page, attrs){Jurisdiction.new}

  class CspStatus
    include Virtus.model
    attribute :value, String, default: "visible"
    attribute :notes, String, default: nil
    class Validator < ::Dry::Validation::Schema
      key(:id, &:str?)
      key(:title, &:str?)
    end
  end
  attribute :cspStatus, CspStatus, default: -> (page, attrs){CspStatus.new}


  class License
    include Virtus.model
    attribute :title, String, default: "CC BY 4.0 US"
    attribute :URL, String, default: "http://creativecommons.org/licenses/by/4.0/us/"
    attribute :rightsHolder, String, default: "Common Curriculum, Inc."
    class Validator < ::Dry::Validation::Schema
      key(:title, &:str?)
      key(:URL, &:str?)
      key(:rightsHolder, &:str?)
    end
  end
  attribute :license, License, default: -> (page, attrs){License.new}

  attribute :educationLevels, Array[String], default: []
  EDUCATION_LEVELS = [
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

  class Validator < ::Dry::Validation::Schema
    key(:title, &:str?)
    key(:subject, &:str?)
    key(:educationLevels) {|attr| attr.empty? | attr.in_education_levels?}
    def in_education_levels?(value)
      # the intersection of the array should produce an array of the same length
      # as given if all the given education levels are in the EDUCATION_LEVELS set
      (EDUCATION_LEVELS & value).length == value.length
    end
  end

  def self.validate(model)
    # pp model.attributes
    self_validations = Validator.new.call(model.attributes)
    return self_validations.messages unless self_validations.messages.empty?

    jurisdiction_validations = Jurisdiction::Validator.new.call(model.jurisdiction.attributes)
    return jurisdiction_validations.messages unless jurisdiction_validations.messages.empty?

    license_validations = License::Validator.new.call(model.license.attributes)
    return license_validations.messages unless license_validations.messages.empty?

    return true
  end

  def self.find(id)
    attrs = $db[:standard_sets].find({_id: id}).first
    self.from_mongo(attrs)
  end

  def self.update(doc, opts={})
    old_version    = $db[:standard_sets].find({_id: doc[:id]}).to_a.first || {}
    if old_version
      self.save_version(old_version)
    end

    # Set the version
    doc[:version] = old_version[:version] || 0
    doc[:version] = doc[:version] + 1
    doc[:updatedAt] = DateTime.now()

    id = doc[:id]

    # Set the ID
    doc.delete(:id)
    standards = doc[:standards]
    doc[:standardsCount] = standards&.length || 0

    if id == nil
      pp doc
      raise "_id is nil"
    end

    # Replace the document
    doc = $db[:standard_sets].find({_id: id}).find_one_and_update(doc, {upsert: true, return_document: :after})

    # Cache standards
    unless opts[:cache_standards] == false
      CachedStandards.one(doc)
    end

    # Send to algolia
    unless opts[:send_to_algolia] == false
      SendToAlgolia.standard_set(doc)
    end
  end

  def self.save_version(old_version)
    old_version["standardSetId"] = old_version["_id"]
    old_version["_id"] = SecureRandom.csp_uuid()
    old_version["createdAt"] = Time.now
    $db[:standard_set_versions].insert_one(old_version)
  end

  def self.from_mongo(attrs)
    attrs[:id] = attrs.delete("_id")
    self.new(attrs)
  end


end
