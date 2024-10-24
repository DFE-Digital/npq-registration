class AddUniqueConstraintToEcfIdInApplications < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :applications, :ecf_id
    add_index :applications, :ecf_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :applications, :ecf_id
    add_index :applications, :ecf_id, algorithm: :concurrently
  end
end
