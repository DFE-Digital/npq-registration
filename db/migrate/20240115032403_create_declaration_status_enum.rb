class CreateDeclarationStatusEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE TYPE declaration_status_enum AS ENUM ('eligible', 'payable', 'paid', 'voided', 'ineligible', 'awaiting_clawback', 'clawed_back');
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE IF EXISTS declaration_status_enum;
    SQL
  end
end
