require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Applications endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :senior_leadership, course_group:) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
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

  describe "accept/reject actions" do
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ApplicationResponse", version: :v3)
    end

    it_behaves_like "an API create on existing resource endpoint documentation",
                    "/api/v3/npq-applications/{id}/accept",
                    "NPQ Applications",
                    "Accept an NPQ application",
                    "The NPQ application being accepted",
                    "#/components/schemas/ApplicationResponse",
                    "#/components/schemas/ApplicationAcceptRequest" do
      let(:resource) { application }
      let(:type) { "npq-application-accept" }
      let(:new_schedule) { create(:schedule, :npq_leadership_spring, course_group:, cohort:) }
      let(:attributes) { { funded_place: false, schedule_identifier: new_schedule.identifier } }
      let(:invalid_attributes) { { funded_place: nil } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:status] = "accepted"
        end
      end
    end

    it_behaves_like "an API create on existing resource endpoint documentation",
                    "/api/v3/npq-applications/{id}/reject",
                    "NPQ Applications",
                    "Reject an NPQ application",
                    "The NPQ application being rejected",
                    "#/components/schemas/ApplicationResponse" do
      let(:resource) { application }
      let(:type) { "npq-application-reject" }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:status] = "rejected"
        end
      end
    end
  end

  it_behaves_like "an API update endpoint documentation",
                  "/api/v3/npq-applications/{id}/change-funded-place",
                  "NPQ Applications",
                  "Change funded place value of an NPQ application",
                  "The NPQ application after changing the funded place",
                  "#/components/schemas/ApplicationResponse",
                  "#/components/schemas/ApplicationChangeFundedPlaceRequest" do
    let(:application) { create(:application, :eligible_for_funded_place, lead_provider:, schedule:, cohort:, course:) }
    let(:resource) { application }
    let(:type) { "npq-application-change-funded-place" }
    let(:attributes) { { funded_place: true } }
    let(:invalid_attributes) { { funded_place: nil } }
  end
end
