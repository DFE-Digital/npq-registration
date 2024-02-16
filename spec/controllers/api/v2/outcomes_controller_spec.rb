require "rails_helper"

RSpec.describe Api::V2::OutcomesController, type: "request" do
  describe("index") do
    before { get(api_v2_outcomes_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
