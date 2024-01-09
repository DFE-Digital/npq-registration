class CreateMigrationResults < ActiveRecord::Migration[7.0]
  def change
    create_table :migration_results do |t|
      t.integer :users_count
      t.integer :orphaned_ecf_users_count
      t.integer :orphaned_npq_users_count
      t.integer :duplicate_users_count
      t.integer :matched_users_count

      t.integer :applications_count
      t.integer :orphaned_ecf_applications_count
      t.integer :orphaned_npq_applications_count
      t.integer :duplicate_applications_count
      t.integer :matched_applications_count

      t.timestamps
    end
  end
end
