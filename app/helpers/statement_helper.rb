module StatementHelper
  def statement_name(statement)
    Date.new(statement.year, statement.month).strftime("%B %Y")
  end

  def number_to_pounds(number)
    number_to_currency number, precision: 2, unit: "£"
  end
end
