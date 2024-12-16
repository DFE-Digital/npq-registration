require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ enrolments endpoint", openapi_spec: "v2/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v2/npq-enrolments.csv",
                  "NPQ Enrolments",
                  "NPQ enrolments",
                  "#/components/schemas/EnrolmentsCsvResponse",
                  "#/components/schemas/ListEnrolmentsFilter"
end
