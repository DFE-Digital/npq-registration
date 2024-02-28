json.data do
  json.id @statement.id
  json.type 'statement'
  json.attributes do
    json.month @statement.month
    json.year @statement.year
    json.type @statement.type
    json.cohort @statement.cohort
    json.cut_off_date @statement.cut_off_date
    json.payment_date @statement.payment_date
    json.paid @statement.paid
    json.created_at @statement.created_at
    json.updated_at @statement.updated_at
  end
end