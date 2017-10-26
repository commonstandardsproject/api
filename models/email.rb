require_relative "../config/postmark"
class Email

  def self.send_email(template_name, pr, comment=nil)
    templates = {
      "approval-requested"  => 3694442,
      "approved"            => 3694223,
      "rejected"            => 3694422,
      "admin-comment-added" => 3694441,
      "revise-and-resubmit" => 3694421
    }
    template_model = {
      name:         pr.submitterName,
      URL:          "http://commonstandardsproject.com/edit/pull-requests/" + pr.id,
      jurisdiction: pr.standardSet.jurisdiction.title,
      subject:      pr.standardSet.subject,
      title:        pr.standardSet.title,
    }
    template_model[:comment] = {text: comment} if comment

    PostmarkClient.deliver_with_template(
      from: ENV["POSTMARK_FROM_ADDRESS"],
      to: "#{pr.submitterName} <#{pr.submitterEmail}>",
      template_id: templates[template_name],
      template_model: template_model
    )
  end

end
