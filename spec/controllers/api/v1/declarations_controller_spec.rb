require "rails_helper"

RSpec.describe Api::V1::DeclarationsController, type: "request" do
  describe("index") do
    before { get(api_v1_declarations_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { get(api_v1_declaration_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("create") do
    before { post(api_v1_declarations_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("void") do
    before { put(api_v1_declaration_void_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
