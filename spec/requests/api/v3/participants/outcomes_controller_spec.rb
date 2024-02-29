require "rails_helper"

RSpec.describe API::V3::Participants::OutcomesController, type: "request" do
  describe("index") do
    before { get(api_v3_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("create") do
    before { post(api_v3_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
