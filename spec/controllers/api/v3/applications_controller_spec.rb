require "rails_helper"

RSpec.describe Api::V3::ApplicationsController, type: "request" do
  describe("index") do
    before { get(api_v3_applications_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { get(api_v3_application_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("accept") do
    before { post(api_v3_application_accept_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("reject") do
    before { post(api_v3_application_reject_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
