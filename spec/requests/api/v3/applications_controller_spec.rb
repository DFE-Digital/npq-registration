require "rails_helper"

RSpec.describe API::V3::ApplicationsController, type: "request" do
  describe("index") do
    before { api_get(api_v3_applications_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("show") do
    before { api_get(api_v3_application_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("accept") do
    before { api_post(api_v3_application_accept_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("reject") do
    before { api_post(api_v3_application_reject_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
