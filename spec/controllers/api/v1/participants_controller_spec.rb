require "rails_helper"

RSpec.describe Api::V1::ParticipantsController, type: "request" do
  describe("index") do
    before { get(api_v1_participants_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { get(api_v1_participant_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("change_schedule") do
    before { put(api_v1_participant_change_schedule_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("defer") do
    before { put(api_v1_participant_defer_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("withdraw") do
    before { put(api_v1_participant_withdraw_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("resume") do
    before { put(api_v1_participant_resume_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("outcomes") do
    before { get(api_v1_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
