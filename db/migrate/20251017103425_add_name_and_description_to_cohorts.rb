class AddNameAndDescriptionToCohorts < ActiveRecord::Migration[7.2]
  # table is known to be small and use of transaction for entire migration is preferable

  def up
    add_column :cohorts, :suffix, :integer, default: 1, null: false
    add_column :cohorts, :description, :string, limit: 50

    safety_assured do
      add_column :cohorts, :name, :virtual, type: :varchar, as: "start_year || '-' || suffix", stored: true
      add_index :cohorts, %i[start_year suffix], unique: true
      add_index :cohorts, :name, unique: true
      add_index :cohorts, :description, unique: true
      remove_index :cohorts, :start_year
      add_index :cohorts, :start_year

      execute <<~EOSQL
        UPDATE cohorts SET description=CONCAT(start_year::varchar, ' to ', (start_year + 1)::varchar)
      EOSQL

      change_column_null :cohorts, :description, false
    end
  end

  def down
    safety_assured do
      remove_index :cohorts, :start_year
      add_index :cohorts, :start_year, unique: true

      remove_column :cohorts, :description
      remove_column :cohorts, :name
      remove_column :cohorts, :suffix
    end
  end
end
