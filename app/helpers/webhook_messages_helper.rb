module WebhookMessagesHelper
  def webhook_message_status_tag(webhook_message)
    text = webhook_message.status

    colour = case text
             when "processed"
               "green"
             when "unhandled_message_type", "error", "failed"
               "red"
             else
               "grey"
             end

    govuk_tag(text:, colour:)
  end

  def pre_tagged_pretty_json(json)
    tag.pre(JSON.pretty_generate(json))
  end
end
