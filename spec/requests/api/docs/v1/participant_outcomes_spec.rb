require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participant Outcomes endpoint", type: :request, openapi_spec: "v1/swagger.yaml" do
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
  let(:declaration) { create(:declaration, :completed, application:) }

  before { create(:participant_outcome, declaration:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participants/npq/outcomes",
                  "NPQ Participant Outcomes",
                  "NPQ Outcomes for all participants",
                  "#/components/schemas/ListParticipantOutcomesFilter",
                  "#/components/schemas/ParticipantOutcomesResponse"
end
