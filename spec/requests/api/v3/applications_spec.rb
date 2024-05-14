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
    before { api_post(accept_api_v3_application_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe "POST /api/v3/npq-applications/:ecf_id/reject" do
    let(:application) { create(:application, lead_provider: current_lead_provider) }

    context "when application is pending" do
      it "returns successfully" do
        api_post "/api/v3/npq-applications/#{application.ecf_id}/reject"

        expect(response).to be_successful
        expect(parsed_response.dig("data", "attributes", "status")).to eql("rejected")
      end
    end

    context "when application is accepted" do
      let(:application) { create(:application, lead_provider: current_lead_provider, lead_provider_approval_status: "accepted") }

      it "returns error" do
        api_post "/api/v3/npq-applications/#{application.ecf_id}/reject"

        expect(response).to have_http_status(:unprocessable_entity)

        expect(parsed_response).to be_key("errors")
        expect(parsed_response["errors"][0]["title"]).to eql("application")
        expect(parsed_response.dig("errors", 0, "detail")).to eql("Once accepted an application cannot change state")
      end
    end
  end
end
