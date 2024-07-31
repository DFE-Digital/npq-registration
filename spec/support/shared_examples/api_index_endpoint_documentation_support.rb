# frozen_string_literal: true

RSpec.shared_examples "an API index endpoint documentation" do |url, tag, resource_description, filter_schema_ref, response_schema_ref, sortable|
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

      if sortable
        parameter name: :sort,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": "#/components/schemas/SortingOptions",
                  }
      end

      response "200", "A list of #{resource_description}" do
        let(:id) { resource&.ecf_id }

        schema({ "$ref": response_schema_ref })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { resource&.ecf_id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      if url =~ /participants\/npq\/.*\/outcomes/
        parameter name: :id,
                  in: :path,
                  required: true,
                  schema: {
                    "$ref": "#/components/schemas/IDAttribute",
                  }

        response "404", "Not found", exceptions_app: true do
          let(:id) { SecureRandom.uuid }

          schema({ "$ref": "#/components/schemas/NotFoundResponse" })

          run_test!
        end
      end
    end
  end
end
