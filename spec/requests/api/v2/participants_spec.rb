require "rails_helper"

RSpec.describe "Participant endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Participants::Query }
  let(:serializer) { API::ParticipantSerializer }
  let(:serializer_version) { :v2 }
  let(:serializer_lead_provider) { current_lead_provider }

  describe "GET /api/v2/participants/npq" do
    let(:path) { api_v2_participants_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:user, :with_application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end

  describe "GET /api/v2/participants/npq/:id" do
    let(:resource) { create(:user, :with_application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v2_participant_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "PUT /api/v2/participants/:ecf_id/resume" do
    let(:course_identifier) { application.course.identifier }
    let(:application) { create(:application, :accepted, :withdrawn, lead_provider: current_lead_provider) }
    let(:participant) { application.user }
    let(:participant_id) { participant.ecf_id }

    def path(id = nil)
      resume_api_v2_participant_path(id)
    end

    it_behaves_like "an API resume participant endpoint" do
      def assert_on_successful_response(parsed_response)
        expect(parsed_response["data"]["attributes"]["npq_enrolments"][0]["training_status"]).to eq("active")
      end
    end
  end

  describe "PUT /api/v2/participants/:ecf_id/defer" do
    let(:course_identifier) { application.course.identifier }
    let(:reason) { Participants::Defer::DEFERRAL_REASONS.sample }
    let(:application) { create(:application, :with_declaration, lead_provider: current_lead_provider) }
    let(:participant) { application.user }
    let(:participant_id) { participant.ecf_id }

    def path(id = nil)
      defer_api_v2_participant_path(id)
    end

    it_behaves_like "an API defer participant endpoint" do
      def assert_on_successful_response(parsed_response)
        expect(parsed_response["data"]["attributes"]["npq_enrolments"][0]["training_status"]).to eq("deferred")
      end
    end
  end

  describe "PUT /api/v2/participants/:ecf_id/withdraw" do
    let(:course_identifier) { application.course.identifier }
    let(:reason) { Participants::Withdraw::WITHDRAWL_REASONS.sample }
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:participant) { application.user }
    let(:participant_id) { participant.ecf_id }

    def path(id = nil)
      withdraw_api_v2_participant_path(id)
    end

    it_behaves_like "an API withdraw participant endpoint" do
      def assert_on_successful_response(parsed_response)
        expect(parsed_response["data"]["attributes"]["npq_enrolments"][0]["training_status"]).to eq("withdrawn")
      end
    end
  end

  describe("change_schedule") do
    before { api_put(change_schedule_api_v2_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("outcomes") do
    before { api_get(api_v2_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
