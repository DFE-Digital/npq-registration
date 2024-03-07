require "rails_helper"

RSpec.describe API::V2::Participants::OutcomesController, type: "request" do
  describe("index") do
    before { api_get(api_v2_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("create") do
    before { api_post(api_v2_participant_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
