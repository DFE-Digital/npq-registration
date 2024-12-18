class CreateFinancialChangeLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :financial_change_logs do |t|
      t.string :operation_description
      t.json :data_changes

      t.timestamps
    end
  end
end
