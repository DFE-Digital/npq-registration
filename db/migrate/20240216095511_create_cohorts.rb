class CreateCohorts < ActiveRecord::Migration[7.1]
  def change
    create_table :cohorts do |t|
      t.integer :start_year, null: false
      t.datetime :registration_start_date, null: false

      t.timestamps
    end

    add_index :cohorts, :start_year, unique: true
  end
end
