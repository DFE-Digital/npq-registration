class CreateContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :contracts do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :recruitment_target, null: false
      t.decimal :per_participant, null: false
      t.integer :number_of_payment_periods, null: false
      t.integer :output_payment_percentage, default: 60, null: false
      t.integer :service_fee_installments, null: false
      t.integer :service_fee_percentage, default: 40, null: false
      t.decimal :monthly_service_fee, default: 0.0
      t.decimal :targeted_delivery_funding_per_participant, default: 100.0
      t.boolean :special_course, null: false, default: false

      t.timestamps
    end
  end
end
