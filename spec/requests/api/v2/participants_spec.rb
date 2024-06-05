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
      create(:participant, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end

  describe("show") do
    before { api_get(api_v2_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("change_schedule") do
    before { api_put(api_v2_participant_change_schedule_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("defer") do
    before { api_put(api_v2_participant_defer_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("withdraw") do
    before { api_put(api_v2_participant_withdraw_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("resume") do
    before { api_put(api_v2_participant_resume_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("outcomes") do
    before { api_get(api_v2_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
