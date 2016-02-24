require_relative "activity"
require_relative "standard_set"
require_relative "../lib/securerandom"
require 'dry-validation'

class PullRequest
  include Virtus.model

  attribute :id, String, :default => -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :submitterId, String
  attribute :submitterEmail, String
  attribute :submitterName, String
  attribute :status, String
  attribute :activities, Array[Activity], default: []
  attribute :forkedFromStandardSetId, String
  attribute :standardSet, StandardSet, default: -> (page, attrs) {StandardSet.new}

  class Validator < Dry::Validation::Schema
    key(:submitterId, &:str?)
    key(:submitterEmail, &:str?)
    key(:submitterName, &:str?)
    key(:status){|status| status.inclusion? ["draft", "in-review", "awaiting-changes", "approved", "rejected" ]}
  end

  def self.validate(model)
    attrs_validation = Validator.new.call(model.attributes)
    activites_validation = model.activities.map{|activity|
      Activity.validate(activity)
    }.flatten
    standard_set_validation = StandardSet.validate(model.standardSet)
    attrs_validation.messages + activites_validation.messages + standard_set_validation.messages
  end


  def self.find(id)
    attrs = $db[:pull_requests].find({_id: id}).first
    attrs[:id] = attrs.delete(:_id)
    self.new(attrs)
  end

  def self.find_all
    $db[:pull_requests].find({status: {:$ne => "rejected"}}).to_a.map{|pr|
      self.new(pr)
    }
  end

  def self.can_edit?(model, user)
    return true if user && user["committer"] === true
    return true if model.submitterId === user.id
    return false
  end

  def self.create(user, standard_set_id)
    model = self.new
    if standard_set_id
      model.standardSet = StandardSet.find(standard_set_id)
      model.forkedFromStandardSetId = standard_set_id
    end
    model.submitterId = user["id"]
    model.submitterEmail = user["email"]
    model.submitterName = user["profile"]["name"]
    model.status = "draft"
    save(model)
    model
  end

  def self.save(model)
    attrs = model.attributes
    attrs[:_id] = attrs.delete(:id)
    $db[:pull_requests].insert_one(attrs)
  end

  def self.update(model)
    attrs = model.attributes
    atts.delete(:id)
    atts.delete(:createdAt)
    attrs.updatedAt = Time.now

    $db[:pull_requests]
      .find({_id: model.id})
      .find_one_and_update({
        "$set" => attrs
      })

    model
  end

  def self.add_activity(model, activity)
    is_valid = Activity.validate(activity)
    return is_valid if is_valid.length > 0
    attrs = model.attributes
    atts.delete(:id)
    model = $db[:pull_requests]
      .find({_id: model.id})
      .find_one_and_update({
        "$push" => { "activity" => activity.attributes }
      })
  end

  def self.change_status(id, status, send_notice=false)
    model = self.new($db[:pull_requests]
      .find({_id: id})
      .find_one_and_update({
        "$set" => {"status" => status}
      }, {upsert: true, return_document: :after}))

    if status == "approved"
      StandardSet.update(model.attributes[:standardSet])
      # apply the standard set to the one it was forked from
    end

    if send_notice
      send_notice(id, status)
    end
    model
  end

  def self.send_notice(id, status)
    model = find(id)
    case status
    when "approved"
      PostmarkClient
      # SendEmail
    when "rejected"
      # send email
    when "awaiting-changes"
      # send email asking to await changes
    when "in-review"
      # add task to asana
      # slack us
      # send email
    end
  end

end