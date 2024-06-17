# frozen_string_literal: true

RSpec.shared_examples "an API update endpoint documentation" do |url, tag, resource_description, response_description, response_schema_ref, request_schema_ref|
  path url do
    put resource_description do
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

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": request_schema_ref,
                }

      let(:params) do
        {
          data: {
            type: action,
            attributes:,
          },
        }
      end

      response "200", response_description do
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

      response "400", "Bad request" do
        let(:id) { resource.ecf_id }
        let(:params) { { data: {} } }

        schema({ "$ref": "#/components/schemas/BadRequestResponse" })

        run_test!
      end

      response "422", "Unprocessable entity" do
        let(:id) { resource.ecf_id }
        let(:attributes) { invalid_attributes }

        schema({ "$ref": "#/components/schemas/UnprocessableEntityResponse" })

        run_test!
      end

      response "404", "Not found", exceptions_app: true do
        let(:id) { SecureRandom.uuid }

        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end
  end
end
