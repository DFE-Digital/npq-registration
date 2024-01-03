class AddIndexToCohorts < ActiveRecord::Migration[7.0]
  def change
    add_index :cohorts, :start_year, unique: true
  end
end
