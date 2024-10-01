class RemoveDefaultFromEcfIdInContractTemplates < ActiveRecord::Migration[7.1]
  def change
    change_column_default :contract_templates, :ecf_id, from: "gen_random_uuid()", to: nil
    change_column_null :contract_templates, :ecf_id, true
    remove_index :contract_templates, :ecf_id, unique: true
    add_index :contract_templates, :ecf_id
  end
end
