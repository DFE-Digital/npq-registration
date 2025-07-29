require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Contracts::ChangePerParticipantController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:contract) { create(:contract) }
  let(:params) { { contracts_change_per_participant: { per_participant: "123.45" } } }

  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "#show" do
      before { get npq_separation_admin_finance_change_per_participant_path(contract) }

      it { is_expected.to have_http_status :success }
    end

    describe "#create" do
      before { post npq_separation_admin_finance_change_per_participant_path(contract), params: }

      it { is_expected.to have_http_status :success }
    end

    describe "#confirmed" do
      before { post confirmed_npq_separation_admin_finance_change_per_participant_path(contract), params: }

      it { is_expected.to redirect_to npq_separation_admin_finance_statement_path(contract.statement) }

      it "flashes success" do
        expect(flash[:success]).to match(/payment per participant changed/i)
      end

      context "when passing invalid value" do
        let(:params) { { contracts_change_per_participant: { per_participant: "" } } }

        it { is_expected.to have_http_status :unprocessable_entity }
      end
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    describe "#show" do
      before { get npq_separation_admin_finance_change_per_participant_path(contract) }

      it { is_expected.to have_http_status :success }
    end

    describe "#create" do
      before { post npq_separation_admin_finance_change_per_participant_path(contract), params: }

      it { is_expected.to have_http_status :success }
    end

    describe "#confirmed" do
      before { post confirmed_npq_separation_admin_finance_change_per_participant_path(contract), params: }

      it { is_expected.to redirect_to npq_separation_admin_finance_statement_path(contract.statement) }

      it "flashes success" do
        expect(flash[:success]).to match(/payment per participant changed/i)
      end
    end
  end

  context "when not logged in" do
    describe "#show" do
      before { get npq_separation_admin_finance_change_per_participant_path(contract) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post npq_separation_admin_finance_change_per_participant_path(contract), params: }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#confirmed" do
      before { post confirmed_npq_separation_admin_finance_change_per_participant_path(contract), params: }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
