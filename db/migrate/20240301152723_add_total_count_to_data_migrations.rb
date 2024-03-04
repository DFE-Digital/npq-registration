class AddTotalCountToDataMigrations < ActiveRecord::Migration[7.1]
  def change
    change_table :data_migrations do |t|
      t.integer :total_count, null: true
    end
  end
end
