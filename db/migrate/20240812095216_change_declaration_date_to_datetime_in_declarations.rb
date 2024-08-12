class ChangeDeclarationDateToDatetimeInDeclarations < ActiveRecord::Migration[7.1]
  def up
    change_column :declarations, :declaration_date, :datetime, precision: nil
  end

  def down
    change_column :declarations, :declaration_date, :date
  end
end
