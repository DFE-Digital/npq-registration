class AddDisabledAtToIttProvidersAndPrivateChildcareProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :itt_providers, :disabled_at, :datetime, null: true
    add_column :private_childcare_providers, :disabled_at, :datetime, null: true
  end
end
