class RemoveCohortFromContracts < ActiveRecord::Migration[7.1]
  def change
    remove_reference :contracts, :cohort, null: false, foreign_key: true
  end
end
