class AddEcfIdToRemainingTables < ActiveRecord::Migration[7.1]
  def change
    add_column :cohorts, :ecf_id, :uuid, null: true
    add_column :schedules, :ecf_id, :uuid, null: true
    add_column :statement_items, :ecf_id, :uuid, null: true
    add_column :participant_id_changes, :ecf_id, :uuid, null: true

    add_index :cohorts, :ecf_id, unique: true
    add_index :schedules, :ecf_id, unique: true
    add_index :statement_items, :ecf_id, unique: true
    add_index :participant_id_changes, :ecf_id, unique: false
  end
end
