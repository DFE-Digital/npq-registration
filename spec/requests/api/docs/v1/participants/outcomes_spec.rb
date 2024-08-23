require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participant Outcomes endpoint", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :senior_leadership, course_group:) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let(:application) do
    create(
      :application,
      :accepted,
      course:,
      lead_provider:,
      cohort:,
      schedule:,
    )
  end
  let(:participant) { application.user }
  let(:declaration) { create(:declaration, :completed, application:) }

  before { create(:participant_outcome, declaration:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participants/npq/{id}/outcomes",
                  "NPQ Participant Outcomes",
                  "NPQ Outcomes for a single participant",
                  nil,
                  "#/components/schemas/ParticipantOutcomesResponse" do
    let(:resource) { participant }
  end

  it_behaves_like "an API create on resource endpoint documentation",
                  "/api/v1/participants/npq/{id}/outcomes",
                  "NPQ Participant Outcomes",
                  "Submit a NPQ Outcome for a single participant",
                  "The details of an NPQ Outcome",
                  "#/components/schemas/ParticipantOutcomeResponse",
                  "#/components/schemas/ParticipantOutcomeCreateRequest" do
    let(:resource) { participant }
    let(:type) { "npq-outcome-confirmation" }
    let(:attributes) do
      {
        course_identifier: course.identifier,
        state: "passed",
        completion_date: "2021-05-31",
      }
    end
    let(:invalid_attributes) do
      {
        course_identifier: course.identifier,
        state: nil,
        completion_date: "2021-05-31",
      }
    end
  end
end
