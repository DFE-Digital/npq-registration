class AddUniqueIndexToStatements < ActiveRecord::Migration[7.1]
  def change
    add_index :statements, %i[lead_provider_id cohort_id year month], unique: true
  end
end
