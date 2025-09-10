Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "api" => "API",
    "api_token" => "APIToken",
    "npq" => "NPQ",
    "stream_api_requests_to_big_query_job" => "StreamAPIRequestsToBigQueryJob",
  )
end
