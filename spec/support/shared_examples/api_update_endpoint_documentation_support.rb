# frozen_string_literal: true

RSpec.shared_examples "an API update endpoint documentation", :exceptions_app do |url, tag, resource_description, response_description, response_schema_ref, request_schema_ref|
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

      if request_schema_ref.present?
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
              type:,
              attributes:,
            },
          }
        end
      end

      response "200", response_description do
        let(:id) { resource.ecf_id }

        schema({ "$ref": response_schema_ref })

        after do |example|
          if defined?(response_example)
            example_spec = {
              "application/json" => {
                examples: {
                  success: {
                    value: response_example,
                  },
                },
              },
            }
            example.metadata[:response][:content] = example_spec
          end
        end

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { resource.ecf_id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      if request_schema_ref.present?
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
      end

      response "404", "Not found" do
        let(:id) { SecureRandom.uuid }

        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end
  end
end
