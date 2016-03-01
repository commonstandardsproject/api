require 'asana'
require_relative "../config/asana"

class AsanaTask

  def self.create_task(pr_id, submitterName, submitterEmail)
    url = "http://commonstandardsproject.com/pull-requests/#{pr_id}"
    Asana::Resources::Task.create(AsanaClient,
      projects: [ENV["ASANA_PR_PROJECT"]],
      name: "PR from #{submitterName}",
      notes: url,
      completed: true,
      assignee: ENV["ASANA_PR_ASSIGNEE_ID"]
    )
  end

  def self.revise_and_resubmit(task_id)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: true)
    task.add_comment(text: "Sent back for review")
  end

  def self.approval_requested(task_id)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: false)
    task.add_comment(text: "Submittered requested approval")
  end

  def self.add_comment_from_submitter(task_id, comment, submitterName)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: false)
    task.add_comment(text: "#{submitterName}: #{comment}")
  end

  def self.add_comment_from_approver(task_id, comment, approverName)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.add_comment(text: "ADMIN: #{approverName}: #{comment}")
  end

  def self.approve(task_id)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: true)
    task.add_comment(text: "Approved PR")
  end

  def self.reject(task_id)
    task = Asana::Resources::Task.find_by_id(AsanaClient, task_id)
    task.update(completed: true)
    task.add_comment(text: "Rejected PR")
  end

end
