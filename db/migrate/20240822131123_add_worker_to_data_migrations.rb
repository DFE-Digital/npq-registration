class AddWorkerToDataMigrations < ActiveRecord::Migration[7.1]
  def change
    add_column :data_migrations, :worker, :integer
  end
end
