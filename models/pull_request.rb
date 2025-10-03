require_relative "activity"
require 'virtus_convert'
require_relative "user"
require_relative "standard_set"
require_relative "asana_task"
require_relative "email"
require_relative "../lib/securerandom"
require 'dry-validation'

class PullRequest
  include Virtus.model

  attribute :id, String, :default => -> (page, attrs) { SecureRandom.csp_uuid() }
  attribute :submitterId, String
  attribute :submitterEmail, String, default: "noemail@example.com"
  attribute :submitterName, String
  attribute :status, String, default: "draft"
  attribute :statusComment, String
  attribute :activities, Array[Activity], default: []
  attribute :forkedFromStandardSetId, String
  attribute :standardSet, StandardSet, default: -> (page, attrs) {StandardSet.new}
  attribute :standardsCount, Integer, default: 0
  attribute :asanaTaskId, String
  attribute :createdAt, DateTime
  attribute :updatedAt, DateTime
  attribute :updatedAtDate, DateTime
  attribute :pullRequestUrl, String
  attribute :title, String

  STATUSES = ["draft", "approval-requested", "revise-and-resubmit", "approved", "rejected" ]
  HUMANIZED_STATUSES = {
    "draft"               => "Draft",
    "approval-requested"  => "Approval Requested",
    "revise-and-resubmit" => "Revise and Resubmit",
    "approved"            => "Approved",
    "rejected"            => "Rejected"
  }

  class Validator < ::Dry::Validation::Schema
    key(:submitterId, &:str?)
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
    $db[:pull_requests].find({status: {:$ne => "rejected"}}).limit(100).to_a.map{|pr|
      self.from_mongo(pr)
    }
  end

  def self.find_query(query, opts = {})
    $db[:pull_requests].find(query, opts).to_a.map{|doc|
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
      model.standardsCount = forked_standard_set.standards.keys.length
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
    model.updatedAtDate = Time.now()
    model.id = SecureRandom.csp_uuid()
    model.createdAt = Time.now
    model.pullRequestUrl = "https://commonstandardsproject.com/edit/pull-requests/#{model.id}"

    insert(model)
    # self.create_asana_task(model)
    model
  end

  def self.insert(model)
    attrs = ::VirtusConvert.new(model).to_hash
    attrs[:_id] = attrs.delete(:id)
    $db[:pull_requests].insert_one(attrs)
  end

  def self.create_asana_task(model, completed=true)
    # task = AsanaTask.create_task(model, completed)
    # model.asanaTaskId = task.gid
    # self.update(model)
  end

  def self.user_update(params)
    model = self.new(params)
    return [false, self.validate(model)] if self.validate(model) != true

    standard_set = ::VirtusConvert.new(model).to_hash[:standardSet]
    standards = standard_set[:standards] || {}
    # only let the user update the standard set
    attrs = {
      title: "#{model.standardSet.jurisdiction.title}: #{model.standardSet.subject}: #{model.standardSet.title}",
      standardSet: standard_set,
      standardsCount: standards.keys.length || 0
    }
    new_model = self.from_mongo(update_in_mongo(model.id, attrs))
    return [true, new_model]
  end

  def self.update(model)
    model.updatedAt = Time.now
    # Old updatedAt dates were strings so another field was added. To resolve this,
    # 1. all updatedAt strings should be turned into dates
    # 2. The Polytomic task should be updated to look at updatedAt
    # 3. Remove the updatedAtDate field
    model.updatedAtDate = Time.now
    model.title = "#{model.standardSet.jurisdiction.title}: #{model.standardSet.subject}: #{model.standardSet.title}"
    model.standardsCount = model.standardSet&.standards&.keys.length || 0
    attrs = ::VirtusConvert.new(model).to_hash
    attrs.delete(:id)

    update_in_mongo(model.id, attrs)

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
    model = $db[:pull_requests]
      .find({_id: model.id})
      .find_one_and_update({
        "$push" => { "activities" => activity.to_hash }
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
    if user["isCommitter"] == true
      Email.send_email("admin-comment-added", model, comment)
      # AsanaTask.add_comment_from_approver(model.asanaTaskId, comment, user["profile"]["name"])
    else
      # AsanaTask.add_comment_from_submitter(model.asanaTaskId, comment, user["profile"]["name"], model)
    end
  end

  def self.change_status(id, status, comment, send_notice=false)
    return false unless STATUSES.include? status

    model = self.find(id)

    if status == "approved"
      StandardSet.update(::VirtusConvert.new(model).to_hash[:standardSet])
      Jurisdiction.approve(model.standardSet.jurisdiction.id)
    end

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


    send_notice(model, status, comment) if send_notice

    model
  end

  def self.send_notice(model, status, comment)

    case status
    when "approved"
      Email.send_email("approved", model, comment)
      # AsanaTask.approve(model.asanaTaskId, model)
    when "rejected"
      Email.send_email("rejected", model, comment)
      # AsanaTask.reject(model.asanaTaskId, model)
    when "revise-and-resubmit"
      Email.send_email("revise-and-resubmit", model, comment)
      # AsanaTask.revise_and_resubmit(model.asanaTaskId, model)
    when "approval-requested"
      Email.send_email("approval-requested", model, comment)
      # AsanaTask.approval_requested(model.asanaTaskId, model)
    end
  end

  def self.from_mongo(attrs)
    return nil if attrs.nil?
    attrs[:id] = attrs.delete("_id")
    model = self.new(attrs)
    model
  end

  def self.from_commit(commit_id)
    commit = $db[:commits].find({_id: commit_id}).first
    pr = self.new
    pr.submitterId = User.find_by_email(commit[:committerEmail]).id
    pr.submitterEmail = commit[:committerEmail]
    pr.submitterName = commit[:committerName]
    pr.status = "draft"
    pr.forkedFromStandardSetId = commit[:standardSetId]
    pr.standardSet = StandardSet.find(commit[:standardSetId])
    PullRequest.update(pr)
    # PullRequest.create_asana_task(pr, false)

    operations = commit[:ops].reduce({}){|acc, hash|
      acc[hash["op"]] ||= {}
      acc[hash["op"]]["standardSet." + hash["path"]] = hash["value"]
      acc
    }

    $db[:pull_requests].find({_id: pr.id}).update_one(operations)
    pr
  end

end
