class DeleteResponseComparisons < ActiveRecord::Migration[7.1]
  def change
    drop_table :response_comparisons, if_exists: true do |t|
      t.string :request_path, null: false
      t.string :request_method, null: false
      t.integer :ecf_response_status_code, null: false
      t.integer :npq_response_status_code, null: false
      t.string :ecf_response_body
      t.string :npq_response_body
      t.integer :ecf_response_time_ms, null: false
      t.integer :npq_response_time_ms, null: false
      t.bigint :lead_provider_id, null: false
      t.integer :page
      t.string :npq_response_body_ids, default: [], array: true
      t.string :ecf_response_body_ids, default: [], array: true

      t.timestamps
    end
  end
end
