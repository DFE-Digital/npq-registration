require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::UnpaidController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/statements/unpaid" do
    let(:fake_statements_find) { instance_double("Statements::Find", unpaid: []) }

    before do
      allow(Statements::Find).to receive(:new).and_return(fake_statements_find)

      sign_in_as_admin
    end

    it "calls Statements::Find.unpaid" do
      get(npq_separation_admin_finance_unpaid_index_path)

      expect(fake_statements_find).to have_received(:unpaid).once
    end
  end
end
