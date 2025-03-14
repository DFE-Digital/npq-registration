class ChangeObjectTypeToJsonForVersions < ActiveRecord::Migration[7.1]
  def up
    change_column :versions, :object, :json, using: "object::text::json"
    add_column :versions, :object_changes, :json
  end
end
