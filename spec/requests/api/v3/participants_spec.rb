require "rails_helper"

RSpec.describe "Participant endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Participants::Query }
  let(:serializer) { API::ParticipantSerializer }
  let(:serializer_version) { :v3 }
  let(:serializer_lead_provider) { current_lead_provider }

  describe "GET /api/v3/participants/npq" do
    let(:path) { api_v3_participants_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:participant, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by training_status"
    it_behaves_like "an API index endpoint with filter by from_participant_id"
  end

  describe "GET /api/v3/participants/npq/:id" do
    let(:resource) { create(:user, :with_application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v3_participant_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe("change_schedule") do
    before { api_put(change_schedule_api_v2_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("defer") do
    before { api_put(defer_api_v2_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("withdraw") do
    before { api_put(withdraw_api_v2_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("resume") do
    before { api_put(resume_api_v2_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("outcomes") do
    before { api_get(api_v2_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
