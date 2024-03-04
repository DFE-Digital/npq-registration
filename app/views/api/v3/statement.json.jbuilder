# app/views/api/v3/statements/_statement.json.jbuilder

json.id statement.id
json.month statement.month
json.year statement.year
json.cohort statement.cohort_id
json.cut_off_date statement.deadline_date.strftime("%Y-%m-%d")
json.payment_date statement.payment_date.strftime("%Y-%m-%d") if statement.payment_date
json.created_at statement.created_at.iso8601
json.updated_at statement.updated_at.iso8601
json.paid statement.payment_date.present?
json.type 'npq'