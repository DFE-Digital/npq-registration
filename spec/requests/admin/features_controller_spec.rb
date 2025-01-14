require "rails_helper"

RSpec.describe Admin::FeaturesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { Flipper.enable("test") }

  context "when user is logged in" do
    before { sign_in_as_admin }

    it "changes feature flag" do
      patch "/admin/features/test", params: { feature_flag_name: "test" }
      expect(Flipper.enabled?("test")).to be false
    end

    it "redirects to the show page" do
      patch "/admin/features/test", params: { feature_flag_name: "test" }
      expect(response).to redirect_to(admin_feature_path("test"))
    end
  end

  context "when user is not logged in" do
    it "redirects to the admin sign in page if not signed in" do
      patch "/admin/features/test", params: { feature_flag_name: "test" }
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
