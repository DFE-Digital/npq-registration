# frozen_string_literal: true

RSpec.shared_examples "an API index endpoint documentation" do |url, tag, resource_description, filter_schema_ref, response_schema_ref|
  path url do
    get "Retrieve multiple #{resource_description}" do
      tags tag
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :filter,
                in: :query,
                required: false,
                schema: {
                  "$ref": filter_schema_ref,
                }

      parameter name: :page,
                in: :query,
                required: false,
                schema: {
                  "$ref": "#/components/schemas/PaginationFilter",
                }

      parameter name: :sort,
                in: :query,
                required: false,
                schema: {
                  "$ref": "#/components/schemas/SortingOptions",
                }

      response "200", "A list of #{resource_description}" do
        schema({ "$ref": response_schema_ref })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end
end
