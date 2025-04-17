class CreateAdjustments < ActiveRecord::Migration[7.1]
  def change
    create_table :adjustments do |t|
      t.references :statement, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :amount, default: 0, null: false

      t.timestamps
    end
  end
end
