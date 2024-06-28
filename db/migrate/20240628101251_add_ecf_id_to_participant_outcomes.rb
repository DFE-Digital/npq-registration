class AddEcfIdToParticipantOutcomes < ActiveRecord::Migration[7.1]
  def change
    add_column :participant_outcomes, :ecf_id, :uuid, default: "gen_random_uuid()", null: false
    add_index :participant_outcomes, :ecf_id, unique: true
  end
end
