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

  before { session["user_id"] = current_user.id }

  subject(:page_response) { make_request && response }

  RSpec.shared_examples "it redirects on missing mandatory institution" do
    before do
      allow(RegistrationWizard).to receive(:new).and_return(missing_institution_wizard.new)
      session["registration_store"] = registration_store
      make_request
    end

    context "when working in a school" do
      let(:registration_store) { { "works_in_school" => "yes" } }

      it { is_expected.to redirect_to registration_wizard_show_path("find-school") }
    end

    context "when working in a private nursery" do
      let(:registration_store) do
        { "works_in_childcare" => "yes", "kind_of_nursery" => "private_nursery" }
      end

      it { is_expected.to redirect_to registration_wizard_show_path("have-ofsted-urn") }
    end

    context "when working in an early years setting" do
      let(:registration_store) { { "works_in_childcare" => "yes" } }

      it { is_expected.to redirect_to registration_wizard_show_path("find-childcare-provider") }
    end
  end

  describe "#show" do
    let(:make_request) { get(:show, params: { step: "course-start-date" }) }

    it_behaves_like "it redirects on missing mandatory institution"

    it { is_expected.to have_http_status :success }
    it { expect(page_response.headers).to include "cache-control" => "no-store" }
  end

  describe "#update" do
    let(:wizard_params) { { course_start_date: "yes" } }
    let(:make_request) { patch :update, params: { step: "course-start-date", registration_wizard: wizard_params } }

    it_behaves_like "it redirects on missing mandatory institution"

    it "persists data to session" do
      make_request
      expect(session["registration_store"]["course_start_date"]).to eql("yes")
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

      it "redirects to course-start-date page" do
        expect(response).to redirect_to registration_wizard_show_path("provider-check")
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
end
