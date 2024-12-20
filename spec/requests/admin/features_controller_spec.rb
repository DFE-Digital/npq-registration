require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::PaymentAuthorisationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin
  it "changes feature flag" do
    sign_in_as_admin
    # create an enabled feature flag
    Flipper.enable("test")
    # run controller action
    patch "/admin/features/test", params: { feature_flag_name: "test" }
    # expect the feature flag to be disabled
    expect(Flipper.enabled?("test")).to be false
  end
  it "redirects to the show page" do
    sign_in_as_admin
    # create an enabled feature flag
    Flipper.enable("test")
    # run controller action
    patch "/admin/features/test", params: { feature_flag_name: "test" }
    # expect the feature flag to be disabled
    expect(response).to redirect_to(admin_feature_path("test"))
  end
  it "redirects to the admin sign in page if not signed in" do
    # create an enabled feature flag
    Flipper.enable("test")
    # run controller action
    patch "/admin/features/test", params: { feature_flag_name: "test" }
    # expect the feature flag to be disabled
    expect(response).to redirect_to(sign_in_path)
  end
end
