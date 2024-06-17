require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Applications endpoint", type: :request, openapi_spec: "v1/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :sl, course_group:) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let!(:application) do
    create(
      :application,
      course:,
      lead_provider:,
      cohort:,
      schedule:,
    )
  end

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/npq-applications",
                  "NPQ Applications",
                  "NPQ applications",
                  "#/components/schemas/ListApplicationsFilter",
                  "#/components/schemas/ApplicationsResponse"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v1/npq-applications.csv",
                  "NPQ Applications",
                  "NPQ applications",
                  "#/components/schemas/ApplicationsCsvResponse",
                  "#/components/schemas/ListApplicationsFilter"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v1/npq-applications/{id}",
                  "NPQ Applications",
                  "NPQ application",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
  end

  it_behaves_like "an API create on resource endpoint documentation",
                  "/api/v1/npq-applications/{id}/accept",
                  "NPQ Applications",
                  "Accept an NPQ application",
                  "The NPQ application being accepted",
                  "#/components/schemas/ApplicationResponse",
                  "#/components/schemas/ApplicationAcceptRequest" do
    let(:resource) { application }
    let(:action) { "npq-application-accept" }
    let(:attributes) { { funded_place: false } }
    let(:invalid_attributes) { { funded_place: nil } }
  end

  it_behaves_like "an API create on resource endpoint documentation",
                  "/api/v1/npq-applications/{id}/reject",
                  "NPQ Applications",
                  "Reject an NPQ application",
                  "The NPQ application being rejected",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
    let(:action) { "npq-application-reject" }
  end

  it_behaves_like "an API update endpoint documentation",
                  "/api/v1/npq-applications/{id}/change-funded-place",
                  "NPQ Applications",
                  "Change funded place value of an NPQ application",
                  "The NPQ application after changing the funded place",
                  "#/components/schemas/ApplicationResponse",
                  "#/components/schemas/ApplicationChangeFundedPlaceRequest" do
    let(:application) { create(:application, :eligible_for_funded_place, lead_provider:) }
    let(:resource) { application }
    let(:action) { "npq-application-change-funded-place" }
    let(:attributes) { { funded_place: true } }
    let(:invalid_attributes) { { funded_place: nil } }
  end
end
