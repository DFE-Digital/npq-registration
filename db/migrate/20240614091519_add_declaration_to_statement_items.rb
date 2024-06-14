class AddDeclarationToStatementItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :statement_items, :declaration, foreign_key: true
  end
end
