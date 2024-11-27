class DropDataMigration < ActiveRecord::Migration[7.1]
  def change
    drop_table :data_migrations do |t|
      t.string :model, null: false
      t.integer :processed_count, default: 0, null: false
      t.integer :failure_count, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :total_count
      t.datetime :queued_at
      t.integer :worker
    end
  end
end
