class Email

  def self.send(template_name, pr, comment=nil)
    {
      "submitted": 438823,
      "approved": 438922,
      "rejected": 438821,
      "admin-comment-added": 438822,
      "revise-and-resubmit": 438823,
    }
    template_model = {
      name: pr.submitterName
    }
    template_model[:comment] = {text: comment} if comment

    PostmarkClient.deliver_with_template(
      from: 'robbie@commoncurriculum',
      to: "#{pr.submitterName} <#{pr.submitterEmail}>",
      template_id: template_id,
      template_model: template_model
    )
  end

end
