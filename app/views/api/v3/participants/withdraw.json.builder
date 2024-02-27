# app/views/api/v3/participants/withdraw.json.jbuilder
json.data do
  json.type "participant-withdraw"
  json.attributes do
    json.reason "quality-of-programme-other"  # Example reason, you can set dynamically based on your logic
    json.course_identifier "npq-leading-teaching-development"  # Example course_identifier, set dynamically
  end
end
