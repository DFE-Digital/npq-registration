class AddUniqueConstraintToEcfIdInDeclarations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :declarations, :ecf_id
    add_index :declarations, :ecf_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :declarations, :ecf_id
    add_index :declarations, :ecf_id, algorithm: :concurrently
  end
end
