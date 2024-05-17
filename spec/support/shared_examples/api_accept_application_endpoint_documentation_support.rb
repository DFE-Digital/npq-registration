RSpec.shared_examples "an API accept application endpoint documentation" do |url, response_schema_ref|
  path url do
    post "Accept an NPQ application" do
      operationId :npq_applications_accept
      tags "NPQ Applications"
      consumes "application/json"
      produces "application/json"
      security [api_key: []]

      parameter name: :id,
                in: :path,
                required: true,
                description: "The ID of the NPQ application to accept.",
                schema: {
                  "$ref": "#/components/schemas/IDAttribute",
                }

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: false
                # schema: {
                #   "$ref": "#/components/schemas/ParticipantDeclarationRequest",
                # }

      response "200", "The NPQ application being accepted" do
        let(:id) { resource.ecf_id }

        let(:params) do
          {
            "data": {
              "type": "npq-application-accept",
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
