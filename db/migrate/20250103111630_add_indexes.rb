class AddIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :applications, %i[lead_provider_approval_status lead_provider_id]
    add_index :users, :created_at
  end
end
