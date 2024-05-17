RSpec.shared_examples "an API reject application endpoint documentation" do |url, response_schema_ref|
  path url do
    post "Reject an NPQ application" do
      operationId :npq_applications_reject
      tags "NPQ Applications"
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                description: "The ID of the NPQ application to reject.",
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      response "200", "The NPQ application being rejected" do
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
    end
  end
end
