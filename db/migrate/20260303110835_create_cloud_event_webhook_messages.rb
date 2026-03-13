class CreateCloudEventWebhookMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :cloud_event_webhook_messages do |t|
      t.string "cloud_event_type"
      t.string "cloud_event_id"
      t.string "cloud_event_source"
      t.string "status", default: "pending"
      t.string "status_comment"
      t.jsonb "raw"
      t.datetime "sent_at"
      t.datetime "processed_at"
      t.timestamps
    end
  end
end
