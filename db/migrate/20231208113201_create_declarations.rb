class CreateDeclarations < ActiveRecord::Migration[7.0]
  def change
    create_table :declarations do |t|
      t.references :application, null: false, foreign_key: true
      t.string :state
      t.string :declaration_type
      t.date :declaration_date
      t.references :course, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
