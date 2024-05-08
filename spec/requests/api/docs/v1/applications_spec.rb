require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Applications endpoint", type: :request, openapi_spec: "v1/swagger.yaml" do
  include_context "with authorization for api doc request"

  let!(:application) { create(:application, lead_provider:) }

  it_behaves_like "an API index endpoint documentation",
                  "api/v1/npq-applications",
                  "NPQ Applications",
                  "NPQ applications",
                  "#/components/schemas/ListApplicationsFilter",
                  "#/components/schemas/ApplicationsResponse"

  it_behaves_like "an API show endpoint documentation",
                  "api/v1/npq-applications/{id}",
                  "NPQ Applications",
                  "NPQ application",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end
end
