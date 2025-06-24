Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "api" => "API",
    "api_token" => "APIToken",
    "npq" => "NPQ",
    "participant_outcome_api_request" => "ParticipantOutcomeAPIRequest",
    "qualified_teachers_api_sender" => "QualifiedTeachersAPISender",
    "stream_api_requests_to_big_query_job" => "StreamAPIRequestsToBigQueryJob",
    "send_to_qualified_teachers_api_job" => "SendToQualifiedTeachersAPIJob",
  )
end
