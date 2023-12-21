class AddFrozenAtToStatements < ActiveRecord::Migration[7.0]
  def change
    add_column :statements, :frozen_at, :datetime
  end
end
