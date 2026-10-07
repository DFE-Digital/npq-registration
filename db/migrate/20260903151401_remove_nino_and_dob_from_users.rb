class RemoveNinoAndDobFromUsers < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      remove_column :users, :date_of_birth
      remove_column :users, :national_insurance_number
      remove_column :users, :raw_tra_provider_data
    end
  end

  def down
    add_column :users, :date_of_birth, :date
    add_column :users, :national_insurance_number, :text
    add_column :users, :raw_tra_provider_data, :jsonb
  end
end
