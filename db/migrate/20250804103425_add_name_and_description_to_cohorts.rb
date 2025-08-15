class AddNameAndDescriptionToCohorts < ActiveRecord::Migration[7.2]
  def change
    add_column :cohorts, :name, :string, limit: 8
    add_column :cohorts, :description, :string

    Cohort.find_each do |cohort|
      cohort.update(name: cohort.start_year.to_s,
                    description: "#{cohort.start_year} to #{cohort.start_year.next}")
    end

    safety_assured do
      # the migration ensures non-null values are set for these columns prior
      # to changing the columns to not allow null values
      change_column_null :cohorts, :name, false
      change_column_null :cohorts, :description, false

      # Safe migrations insists on using :concurrently for adding the index but
      # this cannot be used inside a transaction and there are less than 10 records
      add_index :cohorts, :name, unique: true
      add_index :cohorts, :description, unique: true
      remove_index :cohorts, :start_year
      add_index :cohorts, :start_year
    end
  end
end
