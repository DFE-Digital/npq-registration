class AddClawedBackToStatementItems < ActiveRecord::Migration[7.0]
  def change
    add_reference :statement_items, :clawed_back_by, foreign_key: { to_table: :statement_items }
  end
end
