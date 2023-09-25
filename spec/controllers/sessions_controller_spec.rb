require "rails_helper"

RSpec.describe SessionsController do
  include Helpers::JourneyHelper

  it "redirects to the external OIDC provider's signout endpoint" do
    stub_env_variables_for_gai

    expect(controller).to receive(:sign_out_all_scopes)

    root_path = "https://test.host/"
    expected_redirect_url = "https://tra-domain.com:443/connect/signout?client_id=register-for-npq&post_logout_redirect_uri=#{CGI.escape(root_path)}"

    get :destroy

    expect(response).to redirect_to(expected_redirect_url)
  end
end
