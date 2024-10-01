class CreateParityCheckComparisons < ActiveRecord::Migration[7.1]
  def change
    create_table :parity_check_comparisons do |t|
      t.string :path, null: false
      t.string :method, null: false
      t.integer :ecf_status, null: false
      t.integer :npq_status, null: false
      t.boolean :equal, null: false
      t.string :ecf_response, null: false
      t.string :npq_response, null: false

      t.timestamps
    end
  end
end
