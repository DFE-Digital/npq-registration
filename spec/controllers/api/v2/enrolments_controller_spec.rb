require "rails_helper"

RSpec.describe API::V2::EnrolmentsController, type: "request" do
  describe("index") do
    before { get(api_v2_enrolments_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
