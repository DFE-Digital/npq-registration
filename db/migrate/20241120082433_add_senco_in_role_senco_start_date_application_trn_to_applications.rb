class AddSencoInRoleSencoStartDateApplicationTrnToApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :applications, :senco_in_role, :string
    add_column :applications, :senco_start_date, :date
    add_column :applications, :application_trn, :string
  end
end
