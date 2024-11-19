class AddSignificantlyUpdatedAtToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :significantly_updated_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
    add_index :users, :significantly_updated_at
  end
end
