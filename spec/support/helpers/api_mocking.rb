def mock_previous_funding_api_request(course_identifier:, trn:, response:)
  stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/#{trn}?npq_course_identifier=#{course_identifier}")
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
