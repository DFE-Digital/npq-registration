class AddEcfIdToApplicationStates < ActiveRecord::Migration[7.1]
  def change
    add_column :application_states, :ecf_id, :uuid, null: true
    add_index :application_states, :ecf_id, unique: true
  end
end
