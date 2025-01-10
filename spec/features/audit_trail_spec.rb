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
    it "assigns lead provider to whodunnit"
  end

  describe "a public user making changes" do
    it "records the users details"
  end

  describe "changes from the rails console" do
    it "assigns rails console to whodunnit"
  end
end
