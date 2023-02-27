RSpec.shared_context("stub course ecf to identifier mappings") do
  before do
    Course.pluck(:identifier).each do |course_identifier|
      mock_previous_funding_api_request(
        course_identifier: course_identifier,
        trn: "1234567",
        response: ecf_funding_lookup_response(previously_funded: false)
      )
    end
  end
end
