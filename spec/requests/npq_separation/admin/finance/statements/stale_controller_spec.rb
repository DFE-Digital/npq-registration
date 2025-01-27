require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::StaleController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "#index" do
    context "when logged in as admin" do
      before do
        sign_in_as_admin
        create(:statement, :payable, year: 2025, month: 1, marked_as_paid_at: (Statement::AUTHORISATION_GRACE_TIME * 2).ago)
      end

      it "calls Statements::Query with the 'paid' state" do
        get npq_separation_admin_finance_stale_index_path

        expect(response.body).to include("January 2025")
      end
    end

    context "when not logged in as admin" do
      before { get npq_separation_admin_finance_stale_index_path }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
