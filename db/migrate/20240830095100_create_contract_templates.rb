class CreateContractTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :contract_templates do |t|
      t.integer :recruitment_target, null: false
      t.integer :service_fee_installments, null: false
      t.integer :service_fee_percentage, null: false, default: 40
      t.decimal :per_participant, null: false
      t.integer :number_of_payment_periods
      t.integer :output_payment_percentage, null: false, default: 60
      t.decimal :monthly_service_fee, default: 0.0
      t.decimal :targeted_delivery_funding_per_participant, default: 100.0
      t.boolean :special_course, null: false, default: false

      # NPQContract.id from ecf app
      t.uuid :ecf_id, index: true

      t.timestamps
    end
  end
end
