class AddUniqueConstraintToEcfIdInContractTemplates < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :contract_templates, :ecf_id
    add_index :contract_templates, :ecf_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :contract_templates, :ecf_id
    add_index :contract_templates, :ecf_id, algorithm: :concurrently
  end
end
