require "rails_helper"

RSpec.describe Api::V2::DeclarationsController, type: "request" do
  describe("index") do
    before { get(api_v2_declarations_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { get(api_v2_declaration_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("create") do
    before { post(api_v2_declarations_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("void") do
    before { put(api_v2_declaration_void_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
