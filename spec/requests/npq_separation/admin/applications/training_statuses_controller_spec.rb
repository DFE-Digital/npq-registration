# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::Applications::TrainingStatusesController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:application) { create(:application, :accepted) }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#edit" do
      before do
        get edit_npq_separation_admin_applications_training_status_path(application)
      end

      it { is_expected.to have_http_status :success }
      xit { is_expected.to have_attributes body: /Update.*training status/i }
    end

    describe "#update" do
      before do
        patch npq_separation_admin_applications_training_status_path(application, params:)
      end

      context "with valid update" do
        let(:params) { { update_training_status: { training_status: :deferred } } }

        it { is_expected.to redirect_to npq_separation_admin_application_path(application) }
      end

      context "with invalid update" do
        let(:params) { { update_training_status: { training_status: "unexpected" } } }

        it { is_expected.to have_http_status :unprocessable_entity }
        xit { is_expected.to have_attributes body: /Update.*training status/i }
      end
    end
  end

  context "when not logged in" do
    describe "#edit" do
      before { get edit_npq_separation_admin_applications_training_status_path(application) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before do
        patch npq_separation_admin_applications_training_status_path(application, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
