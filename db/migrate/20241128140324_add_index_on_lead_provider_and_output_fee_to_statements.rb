class AddIndexOnLeadProviderAndOutputFeeToStatements < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :statements, %i[lead_provider_id output_fee]
    add_index :statements, :payment_date
  end
end
