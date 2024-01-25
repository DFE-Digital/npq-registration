class RemoveLeadProviderFromContracts < ActiveRecord::Migration[7.1]
  def change
    remove_reference :contracts, :lead_provider, null: false, foreign_key: true
  end
end
