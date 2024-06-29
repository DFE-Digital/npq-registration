require "rails_helper"
require "swagger_helper"

RSpec.describe "Declarations endpoints", type: :request, openapi_spec: "v1/swagger.yaml" do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v2/participant-declarations.csv",
                  "Participant declarations",
                  "Participant declarations",
                  "#/components/schemas/DeclarationsCsvResponse"

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participant-declarations",
                  "Participant Declarations",
                  "Participant Declarations",
                  "#/components/schemas/ListParticipantDeclarationsFilter",
                  "#/components/schemas/ParticipantDeclarationsResponse"

  describe "single declarations" do
    let(:lead_provider) { create(:lead_provider) }
    let(:type) { "participant-declaration" } # check

    it_behaves_like "an API show endpoint documentation",
                    "/api/v1/participant-declarations/{id}",
                    "Participant Declarations",
                    "Participant Declarations",
                    "#/components/schemas/ParticipantDeclarationResponse" do
      let(:application) do
        create(:application,
               :accepted,
               :with_declaration,
               lead_provider:)
      end
      let(:resource) { application.declarations.first }
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participant-declarations/{id}/void",
                    "Participant Declarations",
                    "Void a declaration",
                    "The participant declaration being voided",
                    "#/components/schemas/ParticipantDeclarationResponse" do
      let(:application) do
        create(:application,
               :accepted,
               :with_declaration,
               lead_provider:)
      end
      let(:resource) { application.declarations.first }
    end

    it_behaves_like "an API create on resource endpoint documentation",
                    "/api/v1/participant-declarations",
                    "Participant Declarations",
                    "Declare a participant has reached a milestone",
                    "The participant declaration being created",
                    "#/components/schemas/ParticipantDeclarationResponse",
                    "#/components/schemas/ParticipantDeclarationRequest" do
      let(:cohort) { create(:cohort, :current) }
      let(:course_group) { CourseGroup.find_by(name: "leadership") }
      let(:course) { create(:course, :sl, course_group:) }
      let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
      let(:application) { create(:application, :accepted, cohort:, course:, lead_provider:) }
      let(:declaration_date) { schedule.applies_from + 1.day }

      let(:attributes) do
        {
          participant_id: application.user.ecf_id,
          declaration_type: "started",
          declaration_date: application.schedule.applies_from.rfc3339,
          course_identifier: course.identifier,
        }
      end

      let(:invalid_attributes) { { participant_id: "invalid" } }
    end
  end
end
