require "rails_helper"

RSpec.feature "Recording audit trail via papertrail", :versioning, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "an admin making changes" do
    subject(:change_author) { application.versions.last.whodunnit }

    before do
      sign_in_as_admin

      post npq_separation_admin_applications_change_training_status_path(application, params:)
    end

    let :application do
      create(:application, :accepted).tap do |application|
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
    let(:application) { create :application, lead_provider:, course: }

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
    it "records the users details"
  end

  describe "changes from the rails console" do
    it "assigns rails console to whodunnit"
  end
end
