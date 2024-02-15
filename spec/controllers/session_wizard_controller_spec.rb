require "rails_helper"

RSpec.describe SessionWizardController do
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
  end
end
