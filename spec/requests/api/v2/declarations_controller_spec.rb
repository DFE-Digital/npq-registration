require "rails_helper"

RSpec.describe API::V2::DeclarationsController, type: "request" do
  describe("index") do
    before { api_get(api_v2_declarations_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { api_get(api_v2_declaration_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("void") do
    before { api_put(api_v2_declaration_void_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
