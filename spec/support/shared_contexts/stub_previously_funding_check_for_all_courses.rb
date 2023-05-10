RSpec.shared_context("Stub previously funding check for all courses") do # rubocop:disable RSpec/ContextWording:
  let(:api_call_get_an_identity_id) { raise NotImplementedError }
  let(:api_call_trn) { raise NotImplementedError }

  before do
    Course.pluck(:identifier).each do |course_identifier|
      mock_previous_funding_api_request(
        course_identifier:,
        trn: api_call_trn,
        get_an_identity_id: api_call_get_an_identity_id,
        response: ecf_funding_lookup_response(previously_funded: false),
      )
    end
  end
end
