require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Applications endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :sl, course_group:) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
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
      {
        data: {
          id: "cc6f7cae-e65b-420e-8194-ae41d4458771",
          type: "npq_application",
          attributes: {
            course_identifier: "npq-senior-leadership",
            email: "doe_john_123@emmerich.test",
            email_validated: true,
            employer_name: nil,
            employment_role: nil,
            full_name: "John Doe 123",
            funding_choice: "self",
            headteacher_status: "no",
            ineligible_for_funding_reason: "establishment-ineligible",
            participant_id: "c44ba53f-183f-4eb0-b701-d21ac0acc056",
            private_childcare_provider_urn: nil,
            teacher_reference_number: "1234567",
            teacher_reference_number_validated: false,
            school_urn: "588297",
            school_ukprn: "79637440",
            status: "accepted",
            works_in_school: true,
            cohort: "2023",
            eligible_for_funding: false,
            targeted_delivery_funding_eligibility: false,
            teacher_catchment: true,
            teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
            teacher_catchment_iso_country_code: "GBR",
            itt_provider: "amazing ITT provider 83",
            lead_mentor: true,
            funded_place: false,
            created_at: "2024-06-25T12:01:30Z",
            updated_at: "2024-06-25T12:01:30Z",
            schedule_identifier: "npq-leadership-autumn",
          },
        },
      }
    end

    it_behaves_like "an API create on resource endpoint documentation",
                    "/api/v3/npq-applications/{id}/accept",
                    "NPQ Applications",
                    "Accept an NPQ application",
                    "The NPQ application being accepted",
                    "#/components/schemas/ApplicationResponse",
                    "#/components/schemas/ApplicationAcceptRequest" do
      let(:resource) { application }
      let(:type) { "npq-application-accept" }
      let(:attributes) { { funded_place: false, schedule_identifier: "npq-leadership-spring" } }
      let(:invalid_attributes) { { funded_place: nil } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:status] = "accepted"
        end
      end
    end

    it_behaves_like "an API create on resource endpoint documentation",
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
    let(:application) { create(:application, :eligible_for_funded_place, lead_provider:, schedule:) }
    let(:resource) { application }
    let(:type) { "npq-application-change-funded-place" }
    let(:attributes) { { funded_place: true } }
    let(:invalid_attributes) { { funded_place: nil } }
  end
end
