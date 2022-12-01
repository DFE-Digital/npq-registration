RSpec.shared_context("stub course ecf to identifier mappings") do
  before do
    Course::COURSE_ECF_ID_TO_IDENTIFIER_MAPPING.each_value do |course_identifier|
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=#{course_identifier}")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(
          status: 200,
          body: ecf_funding_lookup_response(previously_funded: false),
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end
  end
end
