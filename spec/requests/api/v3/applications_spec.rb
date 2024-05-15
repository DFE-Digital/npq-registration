require "rails_helper"

RSpec.describe "Application endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Applications::Query }
  let(:serializer) { API::ApplicationSerializer }
  let(:serializer_version) { :v3 }

  describe "GET /api/v3/applications/:id" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v3_application_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "GET /api/v3/npq-applications" do
    let(:path) { api_v3_applications_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by participant_id"
  end

  describe("accept") do
    before { api_post(api_v1_application_accept_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("reject") do
    before { api_post(api_v1_application_reject_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
