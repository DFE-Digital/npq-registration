require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Applications endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :sl, course_group:) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:cohort) { create(:cohort, :current) }
  let(:application) do
    create(
      :application,
      course:,
      lead_provider:,
      cohort:,
      schedule:,
    )
  end

  it_behaves_like "an API index endpoint documentation",
                  "/api/v3/npq-applications",
                  "NPQ Applications",
                  "NPQ applications",
                  "#/components/schemas/ListApplicationsFilter",
                  "#/components/schemas/ApplicationsResponse"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v3/npq-applications/{id}",
                  "NPQ Applications",
                  "NPQ application",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  it_behaves_like "an API reject application endpoint documentation",
                  "/api/v3/npq-applications/{id}/reject",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  it_behaves_like "an API change application funded place endpoint documentation",
                  "/api/v3/npq-applications/{id}/change-funded-place",
                  "#/components/schemas/ApplicationResponse" do
    let(:application) { create(:application, :eligible_for_funded_place, lead_provider:) }
    let(:resource) { application }
  end

  path "/api/v3/npq-applications/{id}/accept" do
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
                required: false,
                schema: {
                  "$ref": "#/components/schemas/ApplicationAcceptRequestV3",
                }

      response "200", "The NPQ application being accepted" do
        let(:id) { application.ecf_id }

        let(:params) do
          {
            "data": {
              "type": "npq-application-accept",
              "attributes": {
                funded_place: true,
                schedule_identifier: "npq-leadership-spring",
              },
            },
          }
        end

        schema({ "$ref": "#/components/schemas/ApplicationResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { application.ecf_id }
        let(:token) { "invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end
end
