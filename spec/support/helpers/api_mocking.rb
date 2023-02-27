def mock_previous_funding_api_request(course_identifier:, trn:, response:)
  base_url = "https://ecf-app.gov.uk/api/v1/npq-funding/#{trn}"

  query_params = {
    npq_course_identifier: course_identifier,
  }

  query_string = CGI.unescape(query_params.to_query)
  url = "#{base_url}?#{query_string}"

  stub_request(:get, url)
    .with(
      headers: {
        "Authorization" => "Bearer ECFAPPBEARERTOKEN",
      },
    )
    .to_return(
      status: 200,
      body: response,
      headers: {
        "Content-Type" => "application/vnd.api+json",
      },
    )
end
