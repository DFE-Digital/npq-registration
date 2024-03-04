json.id statement.id
json.year statement.year
json.month statement.month
json.cohort do
  json.id statement.cohort.id
  json.start_year statement.cohort.start_year
end
json.cut_off_date statement.deadline_date.strftime("%Y-%m-%d")
json.payment_date statement.payment_date.strftime("%Y-%m-%d") if statement.payment_date
json.created_at statement.created_at.iso8601
json.updated_at statement.updated_at.iso8601
json.paid statement.payment_date.present?
json.type "npq"
