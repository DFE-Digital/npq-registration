class CreateContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :contracts do |t|
      t.boolean :special_course, default: false, null: false
      t.references :statement, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :recruitment_target, null: false
      t.decimal :per_participant, null: false
      t.integer :output_payment_percentage, default: 60, null: false
      t.integer :number_of_payment_periods, null: false
      t.integer :service_fee_percentage, default: 40, null: false
      t.integer :service_fee_installments, null: false
      t.references :cohort, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
