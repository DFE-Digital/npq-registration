class ChangeReconcileAmountPrecisionInStatements < ActiveRecord::Migration[7.0]
  def up
    change_column :statements, :reconcile_amount, :decimal, precision: 8, scale: 2
  end
end
