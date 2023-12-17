class ChangeStartYearNotNullInCohorts < ActiveRecord::Migration[7.0]
  def change
    change_column_null :cohorts, :start_year, false
  end
end
