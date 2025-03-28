require "rails_helper"

RSpec.describe RegistrationWizardController do
  before { session["user_id"] = create(:user).id }

  describe "#show" do
    subject(:page_response) { make_request && response }

    let(:make_request) { get(:show, params: { step: "course-start-date" }) }

    it { is_expected.to have_http_status :success }
    it { expect(page_response.headers).to include "cache-control" => "no-store" }
  end

  describe "#update" do
    context "when agreeing to terms" do
      it "persists data to session" do
        patch :update, params: { step: "share-provider", registration_wizard: { can_share_choices: "1" } }
        expect(session["registration_store"]["can_share_choices"]).to eql("1")
      end
    end
  end
end
