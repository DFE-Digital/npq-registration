class ChangeOutcomeStateColumnType < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE outcomes
      ALTER COLUMN state
      TYPE outcome_states
      USING state::outcome_states;
    SQL
  end

  def down
    # Reverting this migration may not be straightforward due to enum type changes
    raise ActiveRecord::IrreversibleMigration
  end
end
