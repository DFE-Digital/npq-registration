require "rails_helper"

RSpec.describe RegistrationWizardController do
  let(:missing_institution_wizard) do
    Class.new do
      def initialize(*args); end
      def respond_to_missing?(*) = true
      def method_missing(*) = raise FundingEligibility::MissingMandatoryInstitution
    end
  end

  let(:current_user) { create(:user) }

  before do
    allow(Rails.configuration.x.teacher_auth).to receive(:enabled).and_return(false)
    session["user_id"] = current_user.id
  end

  subject(:page_response) { make_request && response }

  RSpec.shared_examples "it redirects on missing mandatory institution" do
    before do
      allow(RegistrationWizard).to receive(:new).and_return(missing_institution_wizard.new)
      session[RegistrationWizard::STORE_SESSION_KEY] = registration_store
      make_request
    end

    context "when working in a school" do
      let(:registration_store) { { "works_in_school" => "yes" } }

      it { is_expected.to redirect_to registration_wizard_show_path("choose-school") }
    end

    context "when working in a private nursery" do
      let(:registration_store) do
        { "works_in_childcare" => "yes", "kind_of_nursery" => "private_nursery" }
      end

      it { is_expected.to redirect_to registration_wizard_show_path("have-ofsted-urn") }
    end

    context "when working in an early years setting" do
      let(:registration_store) { { "works_in_childcare" => "yes" } }

      it { is_expected.to redirect_to registration_wizard_show_path("choose-childcare-provider") }
    end
  end

  describe "#show" do
    let(:make_request) { get(:show, params: { step: "course-start-date" }) }

    it_behaves_like "it redirects on missing mandatory institution"

    it { is_expected.to have_http_status :success }
    it { expect(page_response.headers).to include "cache-control" => "no-store" }
  end

  describe "#update" do
    let(:wizard_params) { { course_start_cohort: "2026a" } }
    let(:make_request) { patch :update, params: { step: "course-start-date", registration_wizard: wizard_params } }

    before { create(:cohort, start_year: 2026) }

    it_behaves_like "it redirects on missing mandatory institution"

    it "persists data to session" do
      make_request
      expect(session[RegistrationWizard::STORE_SESSION_KEY]["course_start_cohort"]).to eql("2026a")
    end

    context "when step is being skipped" do
      before do
        allow(RegistrationWizard).to receive(:new).and_return(wizard)
        allow(wizard).to receive(:save!).and_call_original
        allow_any_instance_of(Questionnaires::CourseStartDate)
          .to receive(:skip_step?).and_return(true)

        make_request
      end

      let :wizard do
        RegistrationWizard.new(current_step: "course_start_date",
                               store: {},
                               params: wizard_params,
                               request:,
                               current_user:)
      end

      it "redirects to the check-funding page" do
        expect(response).to redirect_to registration_wizard_show_path("check-funding")
        expect(wizard).not_to have_received(:save!)
      end
    end

    context "when form requirements are not met" do
      before do
        allow_any_instance_of(Questionnaires::CourseStartDate)
          .to receive(:requirements_met?).and_return(false)

        make_request
      end

      it "redirects to home page" do
        expect(response).to redirect_to root_path
      end
    end
  end

  describe "registrations started on an older journey" do
    let(:saved_answers) { { "course_start_cohort" => "2026a", "course_identifier" => "npq-senior-leadership" } }

    before do
      create(:cohort, start_year: 2026)
      session[store_key] = saved_answers
    end

    context "with the outdated store key" do
      let(:store_key) { RegistrationWizard::OUTDATED_STORE_SESSION_KEY }

      context "when visiting a step of the journey" do
        before { get :show, params: { step: "choose-school" } }

        it { expect(response).to redirect_to root_path }
        it { expect(session.key?(store_key)).to be false }
      end

      context "when visiting the start page" do
        before { get :show, params: { step: "start" } }

        it { expect(response).to have_http_status :success }
        it { expect(session.key?(store_key)).to be false }
        it { expect(session[RegistrationWizard::STORE_SESSION_KEY]).not_to include("course_identifier") }
      end

      context "when submitting a step of the journey" do
        before { patch :update, params: { step: "course-start-date", registration_wizard: { course_start_cohort: "2026a" } } }

        it { expect(response).to redirect_to root_path }
        it { expect(session.key?(store_key)).to be false }
        it { expect(session[RegistrationWizard::STORE_SESSION_KEY]).to be_blank }
      end
    end

    context "with the current store key" do
      let(:store_key) { RegistrationWizard::STORE_SESSION_KEY }

      before { get :show, params: { step: "course-start-date" } }

      it { expect(response).to have_http_status :success }
      it { expect(session[store_key]).to include(saved_answers) }
    end
  end
end
