class ChangeFromAndToParticipantIdsToUuidInParticipantIdChanges < ActiveRecord::Migration[7.1]
  def up
    add_column :participant_id_changes, :from_participant_uuid, :uuid
    add_column :participant_id_changes, :to_participant_uuid, :uuid

    execute <<-SQL
      UPDATE participant_id_changes SET from_participant_uuid = users.ecf_id
      FROM users WHERE participant_id_changes.from_participant_id = users.id;
    SQL

    execute <<-SQL
      UPDATE participant_id_changes SET to_participant_uuid = users.ecf_id
      FROM users WHERE participant_id_changes.to_participant_id = users.id;
    SQL

    remove_column :participant_id_changes, :from_participant_id
    remove_column :participant_id_changes, :to_participant_id

    rename_column :participant_id_changes, :from_participant_uuid, :from_participant_id
    rename_column :participant_id_changes, :to_participant_uuid, :to_participant_id

    change_column_null :participant_id_changes, :from_participant_id, false
    change_column_null :participant_id_changes, :to_participant_id, false

    add_index :participant_id_changes, :from_participant_id
    add_index :participant_id_changes, :to_participant_id
  end

  def down
    add_column :participant_id_changes, :from_participant_bigid, :bigint
    add_column :participant_id_changes, :to_participant_bigid, :bigint

    execute <<-SQL
      UPDATE participant_id_changes SET from_participant_bigid = users.id
      FROM users WHERE participant_id_changes.from_participant_id = users.ecf_id;
    SQL

    execute <<-SQL
      UPDATE participant_id_changes SET to_participant_bigid = users.id
      FROM users WHERE participant_id_changes.to_participant_id = users.ecf_id;
    SQL

    remove_column :participant_id_changes, :from_participant_id
    remove_column :participant_id_changes, :to_participant_id

    rename_column :participant_id_changes, :from_participant_bigid, :from_participant_id
    rename_column :participant_id_changes, :to_participant_bigid, :to_participant_id

    change_column_null :participant_id_changes, :from_participant_id, false
    change_column_null :participant_id_changes, :to_participant_id, false

    add_index :participant_id_changes, :from_participant_id
    add_index :participant_id_changes, :to_participant_id
  end
end
