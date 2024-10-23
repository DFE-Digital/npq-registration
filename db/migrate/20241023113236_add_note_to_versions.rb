class AddNoteToVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :versions, :note, :string
  end
end
