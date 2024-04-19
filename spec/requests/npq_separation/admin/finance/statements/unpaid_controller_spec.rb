require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::UnpaidController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/statements/unpaid" do
    before do
      allow(Statements::Query).to receive(:new).and_call_original

      sign_in_as_admin
    end

    it "calls Statements::Query with the 'open' and 'payable' states" do
      get(npq_separation_admin_finance_unpaid_index_path)

      expect(Statements::Query).to have_received(:new).with(state: "open,payable").once
    end
  end
end
