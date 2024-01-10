class CreateCohorts < ActiveRecord::Migration[7.0]
  def change
    create_table :cohorts do |t|
      t.integer :start_year

      t.timestamps
    end
  end
end
