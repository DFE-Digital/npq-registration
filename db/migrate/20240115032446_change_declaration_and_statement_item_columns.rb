class ChangeDeclarationAndStatementItemColumns < ActiveRecord::Migration[7.1]
  def up
    # Use the USING clause to specify the conversion
    execute <<-SQL
      ALTER TABLE declarations
      ALTER COLUMN state
      TYPE declaration_status_enum
      USING state::declaration_status_enum;

      ALTER TABLE statement_items
      ALTER COLUMN state
      TYPE declaration_status_enum
      USING state::declaration_status_enum;
    SQL
  end

  def down
    # Reverting this migration may not be straightforward due to enum type changes
    raise ActiveRecord::IrreversibleMigration
  end
end
