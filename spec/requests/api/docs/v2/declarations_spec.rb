require "rails_helper"
require "swagger_helper"

RSpec.describe "Declarations endpoints", type: :request, openapi_spec: "v2/swagger.yaml" do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v2/participant-declarations.csv",
                  "Participant declarations",
                  "Participant declarations",
                  "#/components/schemas/DeclarationsCsvResponse"
end
