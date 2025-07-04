require "rails_helper"

RSpec.feature "Recording audit trail via papertrail", :versioning, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:cohort) { create(:cohort, :current, :without_funding_cap) }

  describe "an admin making changes" do
    subject(:change_author) { application.versions.last.whodunnit }

    before do
      sign_in_as_admin

      post npq_separation_admin_applications_change_training_status_path(application, params:)
    end

    let :application do
      create(:application, :accepted, cohort:).tap do |application|
        create(:declaration, application:)
      end
    end

    let :params do
      {
        applications_change_training_status: {
          training_status: :withdrawn,
          reason: Applications::ChangeTrainingStatus::REASON_OPTIONS["withdrawn"].first,
        },
      }
    end

    let(:version) { application.versions.last }

    it "records the admin details" do
      expect(change_author).to eq "Admin #{Admin.maximum(:id)}"
    end
  end

  describe "a lead provider making changes" do
    subject(:change_author) { application.reload.versions.last.whodunnit }

    before do
      travel_to Date.parse("2024-12-13") # ensure schedule identifier is predicable

      APIToken.create_with_known_token!(raw_token, lead_provider:)
      create(:schedule, :npq_leadership_autumn,
             course_group: application.course.course_group,
             cohort: application.cohort)

      post accept_api_v3_application_path(application.ecf_id), headers:
    end

    let(:raw_token) { "a-token" }
    let(:course) { create :"npq-senior-leadership" }
    let(:lead_provider) { create :lead_provider }
    let(:application) { create :application, lead_provider:, course:, cohort: }

    let :headers do
      {
        "Content-Type" => "application/json",
        "Authorization" =>
          ActionController::HttpAuthentication::Token.encode_credentials(raw_token),
      }
    end

    it "records the lead providers details" do
      expect(change_author).to eq "Lead provider #{lead_provider.id}"
    end
  end

  describe "a public user making changes" do
    subject(:change_author) { Application.last.versions.last.whodunnit }

    before do
      create(:cohort, :current)

      allow_any_instance_of(RegistrationWizardController)
        .to receive(:session).and_return({
          "registration_store" => wizard_store,
          :user_id => current_user.id,
        })

      patch registration_wizard_update_path(:check_answers)
    end

    let(:current_user) { create(:user) }
    let(:wizard_store) { build(:registration_wizard_store, current_user:) }

    it "records the lead providers details" do
      expect(change_author).to eq "Public User #{current_user.id}"
    end
  end
end
