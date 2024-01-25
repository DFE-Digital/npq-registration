class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.references :user, null: true, foreign_key: true
      t.references :application, null: true, foreign_key: true
      t.references :course, null: true, foreign_key: true
      t.references :lead_provider, null: true, foreign_key: true
      t.references :school, null: true, foreign_key: true
      t.references :statement, null: true, foreign_key: true
      t.references :statement_item, null: true, foreign_key: true
      t.references :declaration, null: true, foreign_key: true

      # the 'kind' of event, eg. 'declaration made' or 'application submitted'
      t.string :category, null: false

      # short and long description of what's happened, description optional
      t.string :subject, limit: 128, null: false
      t.text :description

      # 1 = debug, 10 = major event?
      t.integer :importance, default: 4, null: false

      t.timestamps
    end
  end
end
