class AddUniqueConstraintToEcfIdInParticipantIdChanges < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :participant_id_changes, :ecf_id
    add_index :participant_id_changes, :ecf_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :participant_id_changes, :ecf_id
    add_index :participant_id_changes, :ecf_id, algorithm: :concurrently
  end
end
