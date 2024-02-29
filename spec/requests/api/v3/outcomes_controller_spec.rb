require "rails_helper"

RSpec.describe API::V3::OutcomesController, type: "request" do
  describe("index") do
    before { get(api_v3_outcomes_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
