require "rails_helper"
require "swagger_helper"

RSpec.describe "Participant Declarations endpoint", type: :request, openapi_spec: "v1/swagger.yaml" do
  include_context "with authorization for api doc request"
end
