require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::PaymentAuthorisationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:statement) { create(:statement) }

  context "when logged in" do
    before { sign_in_as_admin }

    describe "#new" do
      before { get new_npq_separation_admin_finance_payment_authorisation_path(statement) }

      it { is_expected.to have_http_status :success }
      it { is_expected.to have_attributes body: /Check \w+ \d+ statement/i }
    end

    describe "#create" do
      before { post npq_separation_admin_finance_payment_authorisation_path(statement, params:) }

      context "with valid form params" do
        let(:params) { { statements_payment_authorisation_form: { checks_done: "1" } } }

        it { is_expected.to redirect_to npq_separation_admin_finance_statement_path(statement) }
      end

      context "with invalid form params" do
        let(:params) { { statements_payment_authorisation_form: { checks_done: "0" } } }

        it { is_expected.to have_http_status :unprocessable_entity }
        it { is_expected.to have_attributes body: /Check \w+ \d+ statement/i }
      end

      context "without form params" do
        let(:params) { {} }

        it { is_expected.to have_http_status :unprocessable_entity }
        it { is_expected.to have_attributes body: /Check \w+ \d+ statement/i }
      end
    end
  end

  context "when not logged in" do
    describe "#new" do
      before { get new_npq_separation_admin_finance_payment_authorisation_path(statement) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before do
        post npq_separation_admin_finance_payment_authorisation_path(statement, params: {})
      end

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
