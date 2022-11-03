require "rails_helper"

RSpec.describe "FeatureFlags", type: :request do
  describe "GET /feature_flags" do
    context "with #{Services::Feature::CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE} feature flag enabled" do
      before do
        Flipper.enable(Services::Feature::CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE)
      end

      it "returns http success" do
        get "/feature_flags"
        expect(response).to have_http_status(:success)
      end
    end

    context "with #{Services::Feature::CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE} feature flag disabled" do
      before do
        Flipper.disable(Services::Feature::CURRENT_USER_FEATURE_FLAG_MANAGER_ACTIVE)
      end

      it "returns http success" do
        get "/feature_flags"
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
