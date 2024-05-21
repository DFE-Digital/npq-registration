require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Applications endpoint", type: :request, openapi_spec: "v1/swagger.yaml" do
  include_context "with authorization for api doc request"

  let!(:application) { create(:application, lead_provider:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/npq-applications",
                  "NPQ Applications",
                  "NPQ applications",
                  "#/components/schemas/ListApplicationsFilter",
                  "#/components/schemas/ApplicationsResponse"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v1/npq-applications.csv",
                  "NPQ Applications",
                  "NPQ applications",
                  "#/components/schemas/ListApplicationsFilter",
                  "#/components/schemas/ApplicationsCsvResponse"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v1/npq-applications/{id}",
                  "NPQ Applications",
                  "NPQ application",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  it_behaves_like "an API accept application endpoint documentation",
                  "/api/v1/npq-applications/{id}/accept",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  it_behaves_like "an API reject application endpoint documentation",
                  "/api/v1/npq-applications/{id}/reject",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  it_behaves_like "an API change application funded place endpoint documentation",
                  "/api/v1/npq-applications/{id}/change-funded-place",
                  "#/components/schemas/ApplicationResponse" do
    let(:application) { create(:application, :eligible_for_funded_place, lead_provider:) }
    let(:resource) { application }
  end
end
