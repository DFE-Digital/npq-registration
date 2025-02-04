require "rails_helper"

RSpec.describe SessionWizardController do
  describe "show" do
    context "with valid step" do
      before { get :show, params: { step: "sign-in" } }

      it "renders the page" do
        expect(response).to have_http_status :success
      end
    end

    context "with invalid step" do
      it "raises InvalidStep exception" do
        expect {
          get :show, params: { step: "login" }
        }.to raise_exception SessionWizard::InvalidStep
      end
    end
  end

  describe "#update" do
    context "when signing in successfully" do
      let(:admin) { FactoryBot.create(:admin, otp_hash: "123456", otp_expires_at: 15.minutes.from_now) }

      it "sets admin_id in session" do
        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "123456" } }
        expect(session["admin_id"]).to be_present
      end

      it "changes the session to prevent fixation attack" do
        allow(controller).to receive(:reset_session)

        session["session_store"] = { "email" => admin.email }
        patch :update, params: { step: "sign-in-code", session_wizard: { code: "123456" } }

        expect(controller).to have_received(:reset_session)
      end
    end

    context "with invalid step" do
      it "raises InvalidStep exception" do
        expect {
          patch :update, params: { step: "login" }
        }.to raise_exception SessionWizard::InvalidStep
      end
    end
  end
end
