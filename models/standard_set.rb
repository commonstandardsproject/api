require 'pp'
require 'dry-validation'
require_relative '../lib/cache_standards'
require_relative '../lib/send_to_algolia'
require_relative "standard"
require_relative "../lib/securerandom"

class StandardSet
  include Virtus.model

  attribute :id, String, default: -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :title, String
  attribute :subject, String
  attribute :document, Hash
  attribute :createdAt, DateTime
  attribute :updatedAt, DateTime
  attribute :version, Integer, default: 1
  attribute :standards, Hash[String => Standard]

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

  attribute :educationLevels, Array[String]
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
    key(:educationLevels) {|attr| attr.empty? | attr.inclusion?(EDUCATION_LEVELS)}
  end

  def self.validate(model)
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
    old_version    = $db[:standard_sets].find({_id: doc["id"]}).to_a.first || {}
    if old_version["version"] && old_version["version"] > 0
      self.save_version(old_version)
    end

    # Set the version
    doc["version"] = old_version["version"] || 0

    # Set the ID
    doc["_id"]     = doc.delete("id")

    # Replace the document
    doc = $db[:standard_sets].find({_id: doc["_id"]}).find_one_and_update(doc, {upsert: true, return_document: :after})

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
    $db[:standard_set_versions].insert_one(old_version)
  end

  def self.from_mongo(attrs)
    attrs[:id] = attrs.delete("_id")
    self.new(attrs)
  end


end
