class CreateResponseComparisons < ActiveRecord::Migration[7.1]
  def change
    create_table :response_comparisons do |t|
      t.string :request_path, null: false
      t.string :request_method, null: false
      t.integer :ecf_response_status_code, null: false
      t.integer :npq_response_status_code, null: false
      t.string :ecf_response_body
      t.string :npq_response_body
      t.integer :ecf_response_time_ms, null: false
      t.integer :npq_response_time_ms, null: false

      t.references :lead_provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
