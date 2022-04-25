class AddChildcareProviderColumnsToEducationalInstitutions < ActiveRecord::Migration[6.1]
  def change
    add_column :educational_institutions, :early_years_individual_registers, :json, default: []
    add_column :educational_institutions, :provider_early_years_register_flag, :boolean
    add_column :educational_institutions, :provider_compulsory_childcare_register_flag, :boolean
    add_column :educational_institutions, :places, :integer
  end
end
