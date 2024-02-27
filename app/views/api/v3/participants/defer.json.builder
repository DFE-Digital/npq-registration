# app/views/participants/defer.json.jbuilder
json.data do
  json.type "participant-defer"
  json.attributes do
    json.reason "parental-leave"  # Example reason, you can set dynamically based on your logic
    json.course_identifier "npq-senior-leadership"  # Example course_identifier, set dynamically
  end
end
