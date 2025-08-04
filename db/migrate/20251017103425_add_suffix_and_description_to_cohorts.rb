class AddSuffixAndDescriptionToCohorts < ActiveRecord::Migration[7.2]
  # table is known to be tiny and use of transaction for entire migration is
  # preferable to disabling ddl transactions - hence the safety_assured

  def up
    add_column :cohorts, :suffix, :integer, default: 1, null: false
    add_column :cohorts, :description, :string, limit: 50

    safety_assured do
      add_column :cohorts, :identifier, :virtual, type: :varchar, as: "start_year || '-' || suffix", stored: true
      add_index :cohorts, %i[start_year suffix], unique: true
      add_index :cohorts, :identifier, unique: true
      add_index :cohorts, :description, unique: true

      remove_index :cohorts, :start_year, unique: true
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
      remove_column :cohorts, :identifier
      remove_column :cohorts, :suffix
    end
  end
end
