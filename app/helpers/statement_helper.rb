module StatementHelper
  def statement_name(statement)
    Date.new(statement.year, statement.month).strftime("%B %Y")
  end

end
