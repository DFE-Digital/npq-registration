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

  it_behaves_like "an API accept application endpoint documentation",
                  "/api/v3/npq-applications/{id}/accept",
                  "#/components/schemas/ApplicationResponse" do
    let(:resource) { application }
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
end
