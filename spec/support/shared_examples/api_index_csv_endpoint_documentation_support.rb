# frozen_string_literal: true

RSpec.shared_examples "an API index Csv endpoint documentation" do |url, tag, resource_description, response_schema_ref, filter_schema_ref|
  next if url =~ %r{/api/v[12]/} && Rails.configuration.x.disable_legacy_api

  path url do
    get "Retrieve all #{resource_description} in CSV format" do
      tags tag
      produces "text/csv"
      security [api_key: []]

      if filter_schema_ref
        parameter name: :filter,
                  in: :query,
                  required: false,
                  schema: {
                    "$ref": filter_schema_ref,
                  }
      end

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
