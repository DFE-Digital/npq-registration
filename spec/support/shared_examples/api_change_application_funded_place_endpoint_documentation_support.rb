RSpec.shared_examples "an API change application funded place endpoint documentation" do |url, response_schema_ref|
  path url do
    put "Change funded place value of an NPQ application" do
      operationId :npq_applications_change_funded_place
      tags "NPQ Applications"
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                description: "The ID of the NPQ application to change the funded place value.",
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: false,
                schema: {
                  "$ref": "#/components/schemas/ApplicationChangeFundedPlaceRequest",
                }

      response "200", "The NPQ application after changing the funded place" do
        let(:id) { resource.ecf_id }

        let(:params) do
          {
            "data": {
              "type": "npq-application-change-funded-place",
              "attributes": {
                funded_place: true,
              },
            },
          }
        end

        schema({ "$ref": response_schema_ref })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { resource.ecf_id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end
end
