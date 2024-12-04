class CreateBulkOperations < ActiveRecord::Migration[7.1]
  def change
    create_table :bulk_operations do |t|
      t.integer "admin_id"
      t.integer "rows"
      t.text "result"
      t.string "type"

      t.timestamps
    end
  end
end
