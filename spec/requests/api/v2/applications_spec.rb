require "rails_helper"

RSpec.describe "Application endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }

  describe "GET /api/v2/applications/:id" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v2_application_path(id)
    end

    it_behaves_like "an API show endpoint", Applications::Query, API::ApplicationSerializer
  end

  describe("index") do
    before { api_get(api_v1_applications_path) }

    specify { expect(response).to(be_method_not_allowed) }
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
