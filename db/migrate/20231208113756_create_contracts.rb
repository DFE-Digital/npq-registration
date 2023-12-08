class CreateContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :contracts do |t|
      t.boolean :special_course
      t.references :statement, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.decimal :recruitment_target
      t.decimal :per_participant
      t.decimal :output_payment_percentage
      t.decimal :number_of_payment_periods
      t.decimal :service_fee_percentage
      t.decimal :service_fee_installments
      t.references :cohort, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
