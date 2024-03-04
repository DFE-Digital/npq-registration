require "rails_helper"

RSpec.describe API::V3::DeclarationsController, type: "request" do
  describe("index") do
    before { api_get(api_v3_declarations_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { api_get(api_v3_declarations_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
