module StatementHelper
  def statement_name(statement)
    Date.new(statement.year, statement.month).to_fs(:govuk_approx)
  end

  def statement_period(statement)
    "#{statement.year}-#{statement.month}"
  end
end
