class CreateParticipantOutcomeAPIRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :participant_outcome_api_requests do |t|
      t.uuid :ecf_id, default: "gen_random_uuid()", null: false, index: { unique: true }

      t.references :participant_outcome, null: false, foreign_key: true, index: { name: "index_participant_outcome_api_requests_on_participant_outcome" }

      t.string :request_path
      t.integer :status_code
      t.jsonb :request_headers
      t.jsonb :request_body
      t.jsonb :response_body
      t.jsonb :response_headers

      t.timestamps
    end
  end
end
