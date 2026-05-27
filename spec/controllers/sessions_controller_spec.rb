require "rails_helper"

RSpec.describe SessionsController do
  include Helpers::JourneyHelper

  let(:post_logout_uri) { "http://test.host/sign-out" }

  context "with a Get an Identity user is signed in" do
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    let(:user) { create(:user, :with_get_an_identity_id) }

    it "redirects to the external OIDC provider's signout endpoint" do
      expect(controller).to receive(:sign_out_all_scopes)

      expected_redirect_url = "https://tra-domain.com:443/connect/signout?client_id=register-for-npq&post_logout_redirect_uri=#{CGI.escape(post_logout_uri)}"

      get :destroy

      expect(response).to redirect_to(expected_redirect_url)
    end
  end

  context "when a TeacherAuth user is signed in" do
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    let(:user) { create(:user, :with_teacher_auth) }
    let(:id_token) { "test-id-token" }

    it "redirects to the external OIDC provider's signout endpoint" do
      expect(controller).to receive(:sign_out_all_scopes)

      session[:id_token] = id_token

      expected_redirect_url = "/users/auth/teacher_auth/logout?id_token_hint=#{id_token}"

      get :destroy

      expect(response).to redirect_to(expected_redirect_url)
    end
  end

  context "when an admin is signed in" do
    before do
      allow(controller).to receive(:current_admin).and_return(create(:admin))
    end

    it "redirects to admin path" do
      expect(controller).to receive(:sign_out_all_scopes)

      get :destroy

      expect(response).to redirect_to(root_path)
    end
  end

  context "when no user is signed in (callback from provider)" do
    it "redirects to root" do
      expect(controller).to receive(:sign_out_all_scopes)

      get :destroy

      expect(response).to redirect_to(root_path)
    end
  end
end
