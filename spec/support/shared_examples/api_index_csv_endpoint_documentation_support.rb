# frozen_string_literal: true

RSpec.shared_examples "an API index Csv endpoint documentation" do |url, tag, resource_description, filter_schema_ref, response_schema_ref|
  path url do
    get "Retrieve all #{resource_description} in CSV format" do
      tags tag
      produces "text/csv"
      security [api_key: []]

      parameter name: :filter,
                in: :query,
                required: false,
                schema: {
                  "$ref": filter_schema_ref,
                }

      response "200", "A CSV file of #{resource_description}" do
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
