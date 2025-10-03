class ChangeAdjustmentsAmountPrecision < ActiveRecord::Migration[7.2]
  def up
    safety_assured do # this will lock the table whilst updating the column
      change_column :adjustments, :amount, :decimal, precision: ActiveRecord::Type::Decimal::BIGDECIMAL_PRECISION, scale: 2
    end
  end

  def down
    safety_assured do
      change_column :adjustments, :amount, :integer
    end
  end
end
