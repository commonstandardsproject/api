require_relative "../config/postmark"
class Email

  def self.send_email(template_name, pr, comment=nil)
    templates = {
      "approval-requested"  => 438823,
      "approved"            => 438922,
      "rejected"            => 438821,
      "admin-comment-added" => 438822,
      "revise-and-resubmit" => 438823
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
      from: 'robbie@commoncurriculum.com',
      to: "#{pr.submitterName} <#{pr.submitterEmail}>",
      template_id: templates[template_name],
      template_model: template_model
    )
  end

end
