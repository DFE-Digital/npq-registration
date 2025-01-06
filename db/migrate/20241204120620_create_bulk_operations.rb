class CreateBulkOperations < ActiveRecord::Migration[7.1]
  def change
    create_table :bulk_operations do |t|
      t.integer "admin_id", null: false
      t.integer "row_count"
      t.jsonb "result"
      t.string "type", null: false
      t.datetime "started_at"
      t.datetime "finished_at"
      t.integer "ran_by_admin_id"

      t.timestamps
    end
  end
end
