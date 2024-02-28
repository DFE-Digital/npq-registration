class CreateStatements < ActiveRecord::Migration[7.1]
  def change
    create_enum :statement_states, %w[open payable paid]

    create_table :statements do |t|
      t.integer :month, null: false
      t.integer :year, null: false
      t.date :deadline_date
      t.date :payment_date
      t.boolean :output_fee, default: true, null: false
      t.references :cohort, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.datetime :marked_as_paid_at
      t.decimal :reconcile_amount, precision: 8, scale: 2
      t.enum :state, enum_type: "statement_states", default: "open", null: false

      t.timestamps
    end
  end
end
