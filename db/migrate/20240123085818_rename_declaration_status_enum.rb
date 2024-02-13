class RenameDeclarationStatusEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TYPE declaration_status_enum RENAME TO declaration_states;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TYPE declaration_states RENAME TO declaration_status_enum;
    SQL
  end
end
