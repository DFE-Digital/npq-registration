class AddFundingCapToCohorts < ActiveRecord::Migration[7.1]
  def change
    add_column :cohorts, :funding_cap, :boolean, default: false, null: false
  end
end
