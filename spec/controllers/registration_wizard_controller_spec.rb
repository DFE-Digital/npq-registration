require "rails_helper"

RSpec.describe RegistrationWizardController do
  before { session["user_id"] = current_user.id }

  let(:current_user) { create(:user) }

  describe "#show" do
    subject(:page_response) { make_request && response }

    let(:make_request) { get(:show, params: { step: "course-start-date" }) }

    it { is_expected.to have_http_status :success }
    it { expect(page_response.headers).to include "cache-control" => "no-store" }
  end

  describe "#update" do
    let(:wizard_params) { { course_start_date: "yes" } }

    it "persists data to session" do
      patch :update, params: { step: "course-start-date", registration_wizard: wizard_params }
      expect(session["registration_store"]["course_start_date"]).to eql("yes")
    end

    context "when step is being skipped" do
      before do
        allow(RegistrationWizard).to receive(:new).and_return(wizard)
        allow(wizard).to receive(:save!).and_call_original
        allow_any_instance_of(Questionnaires::CourseStartDate)
          .to receive(:skip_step?).and_return(true)
      end

      let :wizard do
        RegistrationWizard.new(current_step: "course_start_date",
                               store: {},
                               params: wizard_params,
                               request:,
                               current_user:)
      end

      it "redirects to course-start-date page" do
        patch :update, params: { step: "course-start-date",
                                 registration_wizard: { course_start_date: "yes" } }

        expect(response).to redirect_to registration_wizard_show_path("provider-check")
        expect(wizard).not_to have_received(:save!)
      end
    end

    context "when form requirements are not met" do
      before do
        allow_any_instance_of(Questionnaires::CourseStartDate)
          .to receive(:requirements_met?).and_return(false)
      end

      it "redirects to home page" do
        patch :update, params: { step: "course-start-date",
                                 registration_wizard: { course_start_date: "yes" } }

        expect(response).to redirect_to root_path
      end
    end
  end
end
