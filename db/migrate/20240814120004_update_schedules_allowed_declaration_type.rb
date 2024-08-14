class UpdateSchedulesAllowedDeclarationType < ActiveRecord::Migration[7.1]
  def up
    # Remove the default
    change_column_default :schedules, :allowed_declaration_types, nil

    # Cast all values to the new enum type
    execute <<-SQL
      alter table schedules alter column allowed_declaration_types type declaration_types[] using allowed_declaration_types::schedule_declaration_types[]::text[]::declaration_types[];
    SQL

    # Re-add the default
    change_column_default :schedules, :allowed_declaration_types, %w[started retained-1 retained-2 completed]

    # Drop the old enum type
    drop_enum :schedule_declaration_types
  end

  def down
    # Restore the old enum type
    create_enum :schedule_declaration_types, %w[started retained-1 retained-2 completed]

    # Remove the default
    change_column_default :schedules, :allowed_declaration_types, nil

    # Cast all values back to the old enum type
    execute <<-SQL
      alter table schedules alter column allowed_declaration_types type schedule_declaration_types[] using allowed_declaration_types::declaration_types[]::text[]::schedule_declaration_types[];
    SQL

    # Re-add the old default
    change_column_default :schedules, :allowed_declaration_types, %w[started retained-1 retained-2 completed]
  end
end
