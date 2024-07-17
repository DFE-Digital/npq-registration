class CreateParticipantIdChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :participant_id_changes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :from_participant, null: false, foreign_key: { to_table: :users }
      t.references :to_participant, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
