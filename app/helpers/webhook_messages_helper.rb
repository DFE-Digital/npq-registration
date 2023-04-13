module WebhookMessagesHelper
  def webhook_message_status_tag(webhook_message)
    status = webhook_message.status

    colour = case status
             when "pending"
               "grey"
             when "processed"
               "green"
             when "unhandled_message_type", "error"
               "red"
             else
               "grey"
             end

    content_tag(:span, status, class: "govuk-tag govuk-tag--#{colour}")
  end

  def pre_tagged_pretty_json(json)
    content_tag(:pre, JSON.pretty_generate(json))
  end
end
