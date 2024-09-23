class RemoveForeignKeysFromParticipantIdChanges < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key :participant_id_changes, column: :from_participant_id
    remove_foreign_key :participant_id_changes, column: :to_participant_id
  end

  def down; end
end
