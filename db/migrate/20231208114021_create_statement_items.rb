class CreateStatementItems < ActiveRecord::Migration[7.0]
  def change
    create_table :statement_items do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :declaration, null: false, foreign_key: true
      t.string :state

      t.timestamps
    end
  end
end
