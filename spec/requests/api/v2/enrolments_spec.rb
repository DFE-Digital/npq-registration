require "rails_helper"

RSpec.describe "Enrolment endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Applications::Query }

  describe "GET /api/v2/npq-enrolments.csv" do
    let(:serializer) { API::EnrolmentsCsvSerializer }
    let(:mock_serializer) { instance_double(API::EnrolmentsCsvSerializer, serialize: nil) }
    let(:path) { api_v2_enrolments_path(format: :csv) }
    let(:resource_id_key) { :ecf_id }

    def create_resource(created_since: nil, updated_since: nil, **attrs)
      application = create(:application, :accepted, **attrs)
      application.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
      application.user.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
      application.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations
      application.user.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations

      application
    end

    it "only returns accepted applications" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider_approval_status: "accepted")).and_call_original

      api_get(path)
    end

    it_behaves_like "an API index Csv endpoint"
    it_behaves_like "an API index Csv endpoint with filter by updated_since"
  end
end
