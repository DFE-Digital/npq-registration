require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::PaidController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/statements/paid" do
    before do
      allow(Statements::Query).to receive(:new).and_call_original

      sign_in_as_admin
    end

    it "calls Statements::Query with the 'paid' state" do
      get(npq_separation_admin_finance_paid_index_path)

      expect(Statements::Query).to have_received(:new).with(state: "paid").once
    end
  end
end
