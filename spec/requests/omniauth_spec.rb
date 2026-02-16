# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Omniauth callbacks", type: :request do
  describe "callback for teacher_auth" do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:teacher_auth] = OmniAuth::AuthHash.new(
        "uid" => "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}",
        "extra" => {
          "raw_info" => {
            "trn" => "1234567",
          },
        },
      )
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:teacher_auth]
    end

    describe "POST /users/auth/teacher_auth" do
      subject { post "/users/auth/teacher_auth/callback" }

      let(:user) { create(:user, :with_teacher_auth) }

      before { allow(User).to receive(:find_or_create_from_teacher_auth).and_return(user) }

      it "calls User.find_or_create_from_teacher_auth to create a user" do
        expect(User).to receive(:find_or_create_from_teacher_auth).with(
          provider_data: OmniAuth.config.mock_auth[:teacher_auth],
          feature_flag_id: nil,
        )
        subject
      end

      it "signs in the user and redirects to the start path" do
        expect(subject).to redirect_to registration_wizard_show_path("course-start-date")
      end

      context "when user creation fails" do
        before { allow(User).to receive(:find_or_create_from_teacher_auth).and_return(nil) }

        it "redirects to the failed sign in path" do
          expect(subject).to redirect_to registration_wizard_show_path("start")
        end
      end
    end
  end

  describe "passthru for tra_openid_connect" do
    describe "GET /users/auth/tra_openid_connect" do
      it "returns a 404 status" do
        get "/users/auth/tra_openid_connect"

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Not found. Authentication passthru.")
      end
    end
  end
end
