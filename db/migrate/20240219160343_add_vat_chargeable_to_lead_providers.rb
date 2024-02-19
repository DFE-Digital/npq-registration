class AddVatChargeableToLeadProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :lead_providers, :vat_chargeable, :boolean, default: true
  end
end
