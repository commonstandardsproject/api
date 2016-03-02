require_relative "activity"
require_relative "standard_set"
require_relative "asana_task"
require_relative "email"
require_relative "../lib/securerandom"
require 'dry-validation'

class PullRequest
  include Virtus.model

  attribute :id, String, :default => -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :submitterId, String
  attribute :submitterEmail, String
  attribute :submitterName, String
  attribute :status, String, default: "draft"
  attribute :statusComment, String
  attribute :activities, Array[Activity], default: []
  attribute :forkedFromStandardSetId, String
  attribute :standardSet, StandardSet, default: -> (page, attrs) {StandardSet.new}
  attribute :asanaTaskId, String
  attribute :createdAt, DateTime
  attribute :updatedAt, DateTime
  attribute :title, String

  STATUSES = ["draft", "approval-requested", "revise-and-resubmit", "approved", "rejected" ]
  HUMANIZED_STATUSES = {
    "draft"               => "Draft",
    "approval-requested"  => "Approval Requested",
    "revise-and-resubmit" => "Revise and Resubmit",
    "approved"            => "Approved",
    "rejected"            => "Rejected"
  }

  class Validator < Dry::Validation::Schema
    key(:submitterId, &:str?)
    key(:submitterEmail, &:str?)
    key(:submitterName, &:str?)
    key(:status){|status| status.inclusion? STATUSES }
  end

  def self.validate(model)
    attrs_validation = Validator.new.call(model.attributes)
    return attrs_validation.messages unless attrs_validation.messages.empty?

    unless model.activities.empty?
       model.activities.each{|activity|
        messages = Activity::Validator.new.call(activity.attributes).messages
        return messages unless messages.empty?
      }.flatten
    end

    standard_set_messages = StandardSet.validate(model.standardSet)
    return standard_set_messages unless standard_set_messages == true

    return true
  end


  def self.find(id)
    self.from_mongo($db[:pull_requests].find({_id: id}).first)
  end

  def self.find_all_active
    $db[:pull_requests].find({status: {:$ne => "rejected"}}).to_a.map{|pr|
      self.from_mongo(pr)
    }
  end

  def self.find_query(query)
    $db[:pull_requests].find(query).to_a.map{|doc|
      self.from_mongo(doc)
    }
  end

  def self.can_edit?(model, user)
    return true if user && user["isCommitter"] === true
    return true if model.submitterId === user["id"]
    return false
  end

  def self.create(user, standard_set_id)
    model = self.new

    if standard_set_id
      forked_standard_set = StandardSet.find(standard_set_id)
      model.standardSet = forked_standard_set
      model.forkedFromStandardSetId = standard_set_id
      activity = Activity.new({
        type: "forked",
        title: "Woohoo! New pull request created by #{user['profile']['name']} from #{forked_standard_set.jurisdiction.title}: #{forked_standard_set.subject}: #{forked_standard_set.title}"
      })
    else
      activity = Activity.new({
        type: "created",
        title: "Woohoo! New pull request created by #{user['profile']['name']}"
      })
    end
    model.submitterId = user["id"]
    model.submitterEmail = user["email"]
    model.submitterName = user["profile"]["name"]
    model.status = "draft"
    model.activities.push(activity)

    insert(model)
    self.create_asana_task(model)
    model
  end

  def self.insert(model)
    attrs = model.as_json
    attrs[:_id] = attrs.delete("id")
    $db[:pull_requests].insert_one(attrs)
  end

  def self.create_asana_task(model)
    task = AsanaTask.create_task(model)
    model.asanaTaskId = task.id
    self.update(model)
  end

  def self.user_update(params)
    model = self.new(params)
    return [false, self.validate(model)] if self.validate(model) != true

    # only let the user update the standard set
    attrs = {
      title: "#{model.standardSet.jurisdiction.title}: #{model.standardSet.subject}: #{model.standardSet.title}",
      standardSet: model.as_json["standardSet"]
    }
    new_model = self.from_mongo(update_in_mongo(model.id, attrs))
    return [true, new_model]
  end

  def self.update(model)
    model.updatedAt = Time.now
    model.title = "#{model.standardSet.jurisdiction.title}: #{model.standardSet.subject}: #{model.standardSet.title}"
    attrs = model.as_json
    attrs.delete(:id)
    attrs.delete(:createdAt)
    attrs.delete(:asanaTaskId)

    update_in_mongo(model.id, attrs.as_json)

    model
  end

  def self.update_in_mongo(id, attrs)
    $db[:pull_requests]
      .find({_id: id})
      .find_one_and_update({
        "$set" => attrs
      }, {upsert: true, return_document: :after})
  end

  def self.add_activity(model, activity)
    validation = Activity::Validator.new.call(activity.attributes)
    if validation.messages.length > 0
      raise ArgumentError, "Validation failed: #{validation.messages.inspect}"
    end
    attrs = model.as_json
    attrs.delete(:id)
    model = $db[:pull_requests]
      .find({_id: model.id})
      .find_one_and_update({
        "$push" => { "activities" => activity.as_json }
      })
  end

  def self.add_comment(model, comment, user)
    activity = Activity.new({
      type: "comment",
      title: comment,
      userName: user["profile"]["name"],
      userId: user["id"]
    })
    self.add_activity(model, activity)
    if user["committer"] == true
      Email.send_email("admin-comment-added", model)
      AsanaTask.add_comment_from_approver(model.asanaTaskId, comment, user["profile"]["name"])
    else
      AsanaTask.add_comment_from_submitter(model.asanaTaskId, comment, user["profile"]["name"], model)
    end
  end

  def self.change_status(id, status, comment, send_notice=false)
    return false unless STATUSES.include? status
    model = self.from_mongo($db[:pull_requests]
      .find({_id: id})
      .find_one_and_update({
        "$set" => {
          "status" => status,
          "statusComment" => comment
        }
      }, {upsert: true, return_document: :after}))

    activity = Activity.new({
      type: "status-change",
      status: HUMANIZED_STATUSES[status],
      title: comment || ""
    })
    self.add_activity(model, activity)

    if status == "approved"
      StandardSet.update(model.standardSet.as_json)
    end

    send_notice(model, status, comment) if send_notice

    model
  end

  def self.send_notice(model, status, comment)

    case status
    when "approved"
      Email.send_email("approved", model, comment)
      AsanaTask.approve(model.asanaTaskId, model)
    when "rejected"
      Email.send_email("rejected", model, comment)
      AsanaTask.reject(model.asanaTaskId, model)
    when "revise-and-resubmit"
      Email.send_email("revise-and-resubmit", model, comment)
      AsanaTask.revise_and_resubmit(model.asanaTaskId, model)
    when "approval-requested"
      AsanaTask.approval_requested(model.asanaTaskId, model)
    end
  end

  def self.from_mongo(attrs)
    return nil if attrs.nil?
    attrs[:id] = attrs.delete("_id")
    model = self.new(attrs)
    model
  end

end
