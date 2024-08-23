# frozen_string_literal: true

RSpec.shared_examples "an API show endpoint documentation", :exceptions_app do |url, tag, resource_description, response_schema_ref|
  path url do
    get "Retrieve a single #{resource_description}" do
      tags tag
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      response "200", "A single #{resource_description}" do
        let(:id) { resource.ecf_id }

        schema({ "$ref": response_schema_ref })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { resource.ecf_id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "404", "Not found" do
        let(:id) { SecureRandom.uuid }

        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end
  end
end
