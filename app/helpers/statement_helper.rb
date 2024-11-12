module StatementHelper
  def statement_name(statement)
    Date.new(statement.year, statement.month).strftime("%B %Y")
  end

  def statement_period(statement)
    "#{statement.year}-#{statement.month}"
  end
end
