require "rails_helper"
require "swagger_helper"

RSpec.describe "Statements endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:statement) { create(:statement, lead_provider:) }

  path "api/v3/statements" do
    get "Retrieve financial statements" do
      tags "Statements"
      produces "application/json"
      security [api_key: []]

      parameter name: :filter,
                in: :query,
                required: false,
                schema: {
                  "$ref": "#/components/schemas/ListStatementsFilter",
                }

      parameter name: :page,
                in: :query,
                required: false,
                schema: {
                  "$ref": "#/components/schemas/PaginationFilter",
                }

      response "200", "A list of statements as part of which the DfE will make output payments for participants" do
        schema({ "$ref": "#/components/schemas/StatementsResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end

  path "api/v3/statements/{id}" do
    get "Retrieve a specific financial statement" do
      tags "Statements"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      response "200", "A specific financial statement" do
        let(:id) { statement.id }
        schema({ "$ref": "#/components/schemas/StatementResponse" })

        run_test!
      end

      response "404", "Not found", exceptions_app: true do
        let(:id) { SecureRandom.uuid }
        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { statement.id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end
end
