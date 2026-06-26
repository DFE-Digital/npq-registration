# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Omniauth callbacks", type: :request do
  describe "callback for teacher_auth" do
    before do
      OmniAuth.config.test_mode = true
    end

    describe "POST /users/auth/teacher_auth" do
      subject { post "/users/auth/teacher_auth/callback" }

      context "when omniauth callback successful" do
        let(:user) { create(:user, :with_teacher_auth) }

        before do
          allow(User).to receive(:find_or_create_from_teacher_auth).and_return(user)
          OmniAuth.config.mock_auth[:teacher_auth] = create(:omniauth_auth_hash)
          Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:teacher_auth]
        end

        it "calls User.find_or_create_from_teacher_auth to create a user" do
          expect(User).to receive(:find_or_create_from_teacher_auth).with(
            provider_data: OmniAuth.config.mock_auth[:teacher_auth],
            feature_flag_id: nil,
          )
          subject
        end

        it "signs in the user and redirects to the account path" do
          expect(subject).to redirect_to account_path
        end

        context "when user creation fails" do
          before { allow(User).to receive(:find_or_create_from_teacher_auth).and_return(nil) }

          it "redirects to the failed sign in path" do
            expect(subject).to redirect_to registration_wizard_show_path("start")
          end
        end
      end
    end
  end

  describe "failure" do
    before { OmniAuth.config.test_mode = true }

    subject(:trigger_teacher_auth_failure) do
      OmniAuth.config.mock_auth[:teacher_auth] = :failure
      post "/users/auth/teacher_auth/callback"
    end

    def sign_in(user)
      allow(User).to receive(:find_by).and_call_original
      allow(User).to receive(:find_by).with(id: anything).and_return(user)
    end

    let(:error_message) do
      "There was an error. Please try again in a few moments. " \
        "If this problem persists, contact us at continuing-professional-development@digital.education.gov.uk"
    end

    context "when the user is already signed in via the provider they were attempting" do
      let(:user) { create(:user, :with_teacher_auth) }

      before { sign_in(user) }

      it "keeps the user signed in and redirects as per a normal sign in" do
        trigger_teacher_auth_failure

        expect(response).to redirect_to(account_path)
        expect(flash[:error]).to be_nil
      end

      it "does not report the failure to Sentry" do
        expect(Sentry).not_to receive(:capture_exception)
        trigger_teacher_auth_failure
      end
    end

    context "when the user is signed in via GAI but attempting TeacherAuth" do
      let(:user) { create(:user, :with_get_an_identity_id) }

      before { sign_in(user) }

      context "when closed registration is enabled and registration is not open for the user" do
        before do
          Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)

          Flipper.disable(Feature::REGISTRATION_OPEN)
        end

        it "redirects to the closed registration exception page" do
          trigger_teacher_auth_failure

          expect(response).to redirect_to(closed_registration_exception_path)
          expect(flash[:error]).to be_nil
        end
      end

      context "when closed registration is not enabled" do
        it "redirects to the home route" do
          trigger_teacher_auth_failure

          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to be_nil
        end
      end

      context "when registration is open globally" do
        before do
          Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)
          Flipper.enable(Feature::REGISTRATION_OPEN)
        end

        it "redirects to the home route" do
          trigger_teacher_auth_failure

          expect(response).to redirect_to(root_path)
        end
      end
    end

    context "when the user is not signed in" do
      it "reports to Sentry, sets an error and redirects to the failed sign in path" do
        expect(Sentry).to receive(:capture_exception)

        trigger_teacher_auth_failure

        expect(response).to redirect_to(registration_wizard_show_path(:start))
        expect(flash[:error]).to eq(error_message)
      end
    end

    context "when signed in via GAI but attempting GAI (same provider mismatch on TeacherAuth path)" do
      let(:user) { create(:user, :with_teacher_auth) }

      before { sign_in(user) }

      it "falls through to the error branch when providers do not match and it is not GAI->TeacherAuth" do
        user.update!(provider: "some_other_provider")
        expect(Sentry).to receive(:capture_exception)

        trigger_teacher_auth_failure

        expect(response).to redirect_to(registration_wizard_show_path(:start))
        expect(flash[:error]).to eq(error_message)
      end
    end
  end

  describe "passthru for tra_openid_connect" do
    describe "GET /users/auth/tra_openid_connect" do
      it "returns a 404 status" do
        get "/users/auth/tra_openid_connect"

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("No route matches")
      end
    end
  end
end
