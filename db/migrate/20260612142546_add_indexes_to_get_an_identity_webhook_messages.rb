class AddIndexesToGetAnIdentityWebhookMessages < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!
  def change
    safety_assured do
      add_index :get_an_identity_webhook_messages, :message_type, algorithm: :concurrently
      add_index :get_an_identity_webhook_messages, :status, algorithm: :concurrently
    end
  end
end
