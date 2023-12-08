class CreateStatements < ActiveRecord::Migration[7.0]
  def change
    create_table :statements do |t|
      t.integer :month
      t.integer :year
      t.date :deadline_date
      t.references :cohort, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.datetime :marked_as_paid_at
      t.decimal :reconcile_amount

      t.timestamps
    end
  end
end
