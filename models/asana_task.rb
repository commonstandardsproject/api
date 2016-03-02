require 'asana'
require_relative "../config/asana"

class AsanaTask

  def self.make_title(model)
    "#{model.submitterName}: #{model.standardSet.jurisdiction.title}: #{model.standardSet.subject}: #{model.standardSet.title}"
  end

  def self.make_notes(model)
    "J: #{model.standardSet.jurisdiction.title}\nS: #{model.standardSet.subject}\nT: #{model.standardSet.title}\n\nPR: http://commonstandardsproject.com/edit/pull-requests/#{model.id}\nEmail: #{model.submitterEmail}"
  end

  def self.create_task(model)
    Asana::Resources::Task.create(AsanaClient,
      projects: [ENV["ASANA_PR_PROJECT"]],
      name: make_title(model),
      notes: make_notes(model),
      completed: true,
      assignee: ENV["ASANA_PR_ASSIGNEE_ID"]
    )
  end

  def self.revise_and_resubmit(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: true, name: make_title(model), notes: make_notes(model))
    task.add_comment(text: "Sent back for review")
  end

  def self.approval_requested(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    title = "APPROVAL REQUESTED " + make_title(model)
    task.update(completed: false, name: title, notes: make_notes(model))
    task.add_comment(text: "Submittered requested approval")
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
    task.update(completed: true, name: title, notes: make_notes(model))
    task.add_comment(text: "Approved PR")
  end

  def self.reject(task_id, model)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    title = "REJECTED " + make_title(model)
    task.update(completed: true, name: title, notes: make_notes(model))
    task.add_comment(text: "Rejected PR")
  end

end
