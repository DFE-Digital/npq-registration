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
    it "persists data to session" do
      patch :update, params: { step: "course-start-date", registration_wizard: { course_start_date: "yes" } }
      expect(session["registration_store"]["course_start_date"]).to eql("yes")
    end
  end
end
