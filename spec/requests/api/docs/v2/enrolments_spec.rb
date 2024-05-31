require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ enrolments endpoint", type: :request, openapi_spec: "v2/swagger.yaml" do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v2/npq-enrolments.csv",
                  "NPQ Enrolments",
                  "NPQ enrolments",
                  "#/components/schemas/ListEnrolmentsFilter",
                  "#/components/schemas/EnrolmentsCsvResponse"
end
