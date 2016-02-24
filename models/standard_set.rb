require 'pp'
require_relative 'cache_standards'
require_relative 'send_to_algolia'
require_relative "standard_set_license"
require_relative "standard_set_jurisdiction"
require_relative "../lib/securerandom"

class StandardSet
  include Virtus.model

  attribute :id, String, :default => -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :title, String
  attribute :subject, String
  attribute :createdAt, DateTime
  attribute :updatedAt, DateTime

  attribute :jurisdiction, StandardSetJurisdiction, default: (page, attrs) -> {StandardSetJurisdiction.new}
  class StandardSetJurisdiction
    include Virtus.model
    attribute :id, String
    attribute :title, String

    class Validator < Dry::Validation::Schema
      key(:id, &:str?)
      key(:title, &:str?)
    end
  end

  attribute :license, StandardSetLicense, default: (page, attrs) -> {StandardSetLicense.new}
  class StandardSetLicense
    include Virtus.model
    attribute :title, String, default: "CC BY 4.0 US"
    attribute :URL, String, default: "http://creativecommons.org/licenses/by/4.0/us/"
    attribute :rightsHolder, String, default: "Common Curriculum, Inc."
    class Validator < Dry::Validation::Schema
      key(:title, &:str?)
      key(:URL, &:str?)
      key(:rightsHolder, &:str?)
    end
  end

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

  class Validator < Dry::Validation::Schema
    key(:title, &:str?)
    key(:subject, &:str?)
    key(:educationLevels) {|attr| attr.inclusion? EDUCATION_LEVELS}
  end

  def self.validate(model)
    self_validations = Validator.new.call(model)
    jurisdiction_validations = StandardSetJurisdiction::Validator.new.call(model.jurisdiction)
    license_validations = StandardSetLicense::Validator.new.call(model.license)
    messages = self_validations.messages + jurisdiction_validations.messages + license_validations.messages
    messages.empty? true : messages
  end

  def self.find(id)
    attrs = $db[:standard_sets].find({_id: id}).first
    attrs[:id] = attrs.delete(:_id)
    self.new(attrs)
  end

  def self.update(doc, opts)
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


end
