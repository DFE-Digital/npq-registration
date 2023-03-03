def mock_previous_funding_api_request(course_identifier:, response:, trn: nil, get_an_identity_id: nil)
  base_url = "https://ecf-app.gov.uk/api/v1/npq/previous_funding"

  query_params = {
    npq_course_identifier: course_identifier,
  }
  query_params[:trn] = trn if trn.present?
  query_params[:get_an_identity_id] = get_an_identity_id if get_an_identity_id.present?

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
