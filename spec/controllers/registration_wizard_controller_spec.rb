require "rails_helper"

RSpec.describe RegistrationWizardController do
  describe "#update" do
    context "when agreeing to terms" do
      it "persists data to sesion" do
        patch :update, params: { step: "share-provider", registration_wizard: { can_share_choices: "1" } }
        expect(session["registration_store"]["can_share_choices"]).to eql("1")
      end
    end

    context "when submitting" do
      before do
        session["registration_store"] = { "can_share_choices" => "1" }
      end

      it "creates a User record" do
        expect {
          patch :update, params: { step: "contact-details", registration_wizard: { email: "valid@example.com" } }
        }.to change(User, :count).by(1)
      end
    end
  end
end
