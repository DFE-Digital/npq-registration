require "rails_helper"

RSpec.describe NpqSeparation::Admin::Applications::RevertToPendingController, :ecf_api_disabled, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:application) { create(:application, :accepted) }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#new" do
      before { get new_npq_separation_admin_applications_revert_to_pending_path(application) }

      it { is_expected.to have_http_status :success }
      it { is_expected.to have_attributes body: /change the status to pending/i }
    end

    describe "#create" do
      before do
        post npq_separation_admin_applications_revert_to_pending_path(application, params:)
      end

      context "with valid form params" do
        let :params do
          { applications_revert_to_pending_form: { change_status_to_pending: "yes" } }
        end

        it { is_expected.to redirect_to npq_separation_admin_application_path(application) }
      end

      context "with invalid form params" do
        let :params do
          { statements_payment_authorisation_form: { change_status_to_pending: "no" } }
        end

        it { is_expected.to have_http_status :unprocessable_entity }
        it { is_expected.to have_attributes body: /change the status to pending/i }
      end

      context "without form params" do
        let(:params) { {} }

        it { is_expected.to have_http_status :unprocessable_entity }
        it { is_expected.to have_attributes body: /change the status to pending/i }
      end
    end
  end

  context "when not logged in" do
    describe "#new" do
      before { get new_npq_separation_admin_applications_revert_to_pending_path(application) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before do
        post npq_separation_admin_applications_revert_to_pending_path(application, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
