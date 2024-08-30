class CreateContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :contracts do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :contract_template, null: false, foreign_key: true

      t.timestamps
    end

    add_index :contracts, %i[statement_id course_id], unique: true
  end
end
