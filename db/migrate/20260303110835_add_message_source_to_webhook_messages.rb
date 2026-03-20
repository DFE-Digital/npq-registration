class AddMessageSourceToWebhookMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :get_an_identity_webhook_messages, :message_source, :string
  end
end
