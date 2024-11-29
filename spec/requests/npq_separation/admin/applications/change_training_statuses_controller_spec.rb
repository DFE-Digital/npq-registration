# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::Applications::ChangeTrainingStatusesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:application) { create(:application, :accepted) }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#new" do
      before do
        get new_npq_separation_admin_applications_change_training_status_path(application)
      end

      it { is_expected.to have_http_status :success }
      it { is_expected.to have_attributes body: /Change.*training status/i }
    end

    describe "#create" do
      before do
        post npq_separation_admin_applications_change_training_status_path(application, params:)
      end

      context "with valid update" do
        let :params do
          {
            applications_change_training_status: {
              training_status: :withdrawn,
              reason: Applications::ChangeTrainingStatus::REASON_OPTIONS["withdrawn"].first,
            },
          }
        end

        it { is_expected.to redirect_to npq_separation_admin_application_path(application) }
      end

      context "with invalid update" do
        let(:params) { { change_training_status: { training_status: "unexpected" } } }

        it { is_expected.to have_http_status :unprocessable_entity }
        it { is_expected.to have_attributes body: /Change.*training status/i }
      end
    end
  end

  context "when not logged in" do
    describe "#edit" do
      before { get new_npq_separation_admin_applications_change_training_status_path(application) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before do
        post npq_separation_admin_applications_change_training_status_path(application, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
