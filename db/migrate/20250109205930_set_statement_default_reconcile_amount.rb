class SetStatementDefaultReconcileAmount < ActiveRecord::Migration[7.1]
  def change
    change_column_default :statements, :reconcile_amount, from: nil, to: 0
  end
end
