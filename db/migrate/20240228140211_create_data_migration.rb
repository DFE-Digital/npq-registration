class CreateDataMigration < ActiveRecord::Migration[7.1]
  def change
    create_table :data_migrations do |t|
      t.string :model, null: false
      t.integer :processed_count, null: false, default: 0
      t.integer :failure_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
