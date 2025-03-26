require "rails_helper"

RSpec.describe RegistrationWizardController do
  subject { response }

  before { session[:user_id] = create(:user).id }

  describe "#show" do
    before { get :show, params: { step: "course-start-date" } }

    it { is_expected.to have_http_status :success }
  end

  describe "#update" do
    context "when agreeing to terms" do
      it "persists data to session" do
        patch :update, params: { step: "course-start-date", registration_wizard: { course_start_date: "yes" } }
        expect(session["registration_store"]["course_start_date"]).to eql("yes")
      end
    end
  end
end
