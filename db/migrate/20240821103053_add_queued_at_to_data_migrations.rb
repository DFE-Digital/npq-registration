class AddQueuedAtToDataMigrations < ActiveRecord::Migration[7.1]
  def change
    add_column :data_migrations, :queued_at, :datetime
  end
end
