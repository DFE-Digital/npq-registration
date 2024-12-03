require "rails_helper"

RSpec.describe "Enrolment endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Applications::Query }

  describe "GET /api/v2/npq-enrolments.csv" do
    let(:serializer) { API::EnrolmentsCsvSerializer }
    let(:mock_serializer) { instance_double(API::EnrolmentsCsvSerializer, serialize: nil) }
    let(:path) { api_v2_enrolments_path(format: :csv) }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:application, :accepted, **attrs)
    end

    it "only returns accepted applications" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider_approval_status: "accepted")).and_call_original

      api_get(path)
    end

    it_behaves_like "an API index Csv endpoint"
    it_behaves_like "an API index Csv endpoint with filter by updated_since"
  end
end
