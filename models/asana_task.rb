require 'asana'
require_relative "../config/asana"

class AsanaTask

  def self.create_task(model, completed=true)
    Asana::Resources::Task.create(AsanaClient,
      projects: [ENV["ASANA_PR_PROJECT"]],
      name: make_title(model),
      notes: make_notes(model),
      completed: completed,
      assignee: ENV["ASANA_PR_ASSIGNEE_ID"],
      custom_fields: self.custom_fields(model, "DRAFT")
    )
  end

  def self.revise_and_resubmit(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: true, name: make_title(model), notes: make_notes(model), custom_fields: self.custom_fields(model, "REVISE_AND_RESUBMIT"))
    task.add_comment(text: "Sent back for review")
  end

  def self.approval_requested(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    title = "APPROVAL REQUESTED " + make_title(model)
    task.update(completed: false, name: title, notes: make_notes(model), custom_fields: self.custom_fields(model, "APPROVAL_REQUESTED"))
    task.add_comment(text: "Submitted request for approval")
  end

  def self.add_comment_from_submitter(task_id, comment, submitterName, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    title = "NEW COMMENT " + make_title(model)
    task.update(completed: false, name: title, notes: make_notes(model))
    task.add_comment(text: "#{submitterName}: #{comment}")
  end

  def self.add_comment_from_approver(task_id, comment, approverName)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.add_comment(text: "ADMIN: #{approverName}: #{comment}")
  end

  def self.approve(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    title = "APPROVED " + make_title(model)
    task.update(completed: true, name: title, notes: make_notes(model), custom_fields: self.custom_fields(model, "APPROVED"))
    task.add_comment(text: "Approved PR")
  end

  def self.reject(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    title = "REJECTED " + make_title(model)
    task.update(completed: true, name: title, notes: make_notes(model), custom_fields: self.custom_fields(model, "REJECTED"))
    task.add_comment(text: "Rejected PR")
  end

  def self.make_title(model)
    "#{model.submitterName}: #{model.standardSet.jurisdiction.title}: #{model.standardSet.subject}: #{model.standardSet.title}"
  end

  def self.make_notes(model)
    "J: #{model.standardSet.jurisdiction.title}\nS: #{model.standardSet.subject}\nT: #{model.standardSet.title}\n\nPR: http://commonstandardsproject.com/edit/pull-requests/#{model.id}\nEmail: #{model.submitterEmail}"
  end

  def self.custom_fields(model, status)
    status_to_asana_code = {
      "DRAFT" => "1156104420836710",
      "REVISE_AND_RESUBMIT" => "1156104420836712",
      "APPROVED" => "1156104420836713",
      "APPROVAL_REQUESTED" => "1156104420836711",
      "REJECTED" => "1156104420836724"
    }
    {
      "1156097036183258": "https://commonstandardsproject.com/edit/pull-requests/#{model.id}", #link
      "1156104420836706": "#{model.submitterName}", #submitter
      "1156104420836727": "#{model.submitterEmail}", #submitter email
      "1156104420836709": status_to_asana_code[status], #status
      "1156104420836716": "#{model.standardSet.jurisdiction.title}", #organization
      "1156104420836719": "#{model.standardSet.title}", #subject
      "1156104420836722": model.standardSet.standards.keys.length, #standards count
      "1156120467564154": model.try(:activities).try(:first).try(:createdAt).try(:strftime, "%a, %b.%e %Y"), # created at
      "1156120467564157": model.forkedFromStandardSetId ? "1156120467564158" : "1156120467564159" # forked from
    }
  end

end
