require "rails_helper"

RSpec.describe SessionsController do
  let(:post_logout_uri) { "http://test.host/sign-out" }

  describe "#confirm_sign_out" do
    render_views

    context "when a user is signed in" do
      before do
        allow(controller).to receive(:current_user).and_return(create(:user))
      end

      it "renders the sign out confirmation page" do
        get :confirm_sign_out

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Are you sure you want to sign out?")
      end

      it "uses the referer as the cancel URL" do
        request.headers["HTTP_REFERER"] = "http://test.host/account"

        get :confirm_sign_out

        cancel_link = Capybara.string(response.body).find_link("Stay signed in")
        expect(cancel_link[:href]).to eq("http://test.host/account")
      end

      it "uses the root path as the cancel URL when there is no referer" do
        get :confirm_sign_out

        cancel_link = Capybara.string(response.body).find_link("Stay signed in")
        expect(cancel_link[:href]).to eq(root_path)
      end

      it "uses the root path as the cancel URL when the referer is from another site" do
        request.headers["HTTP_REFERER"] = "https://another.com/page"

        get :confirm_sign_out

        cancel_link = Capybara.string(response.body).find_link("Stay signed in")
        expect(cancel_link[:href]).to eq(root_path)
      end

      it "uses the root path as the cancel URL when the referer is the sign out page itself" do
        request.headers["HTTP_REFERER"] = "http://test.host/sign-out"

        get :confirm_sign_out

        cancel_link = Capybara.string(response.body).find_link("Stay signed in")
        expect(cancel_link[:href]).to eq(root_path)
      end

      it "uses the root path as the cancel URL when the referer is not a valid URI" do
        request.headers["HTTP_REFERER"] = "http://test.host/  th"

        get :confirm_sign_out

        cancel_link = Capybara.string(response.body).find_link("Stay signed in")
        expect(cancel_link[:href]).to eq(root_path)
      end
    end

    context "when an admin is signed in" do
      before do
        allow(controller).to receive(:current_admin).and_return(create(:admin))
      end

      it "renders the sign out confirmation page" do
        get :confirm_sign_out

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Are you sure you want to sign out?")
      end
    end

    context "when no one is signed in (direct request or callback from a provider after signing out)" do
      it "redirects to root" do
        get :confirm_sign_out

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "#destroy" do
    context "when a Get an Identity user is signed in" do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      let(:user) { create(:user, :with_get_an_identity_id) }

      it "redirects to the external OIDC provider's signout endpoint" do
        expect(controller).to receive(:sign_out_all_scopes)

        expected_redirect_url = "https://tra-domain.com:443/connect/signout?client_id=register-for-npq&post_logout_redirect_uri=#{CGI.escape(post_logout_uri)}"

        delete :destroy

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

        delete :destroy

        expect(response).to redirect_to(expected_redirect_url)
      end
    end

    context "when an admin is signed in" do
      before do
        allow(controller).to receive(:current_admin).and_return(create(:admin))
      end

      it "redirects to admin path" do
        expect(controller).to receive(:sign_out_all_scopes)

        delete :destroy

        expect(response).to redirect_to(root_path)
      end
    end

    context "when no user is signed in" do
      it "redirects to root" do
        expect(controller).to receive(:sign_out_all_scopes)

        delete :destroy

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
