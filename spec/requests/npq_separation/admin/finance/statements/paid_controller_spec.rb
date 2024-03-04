require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::PaidController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/statements/paid" do
    let(:fake_statements_find) { instance_double("Statements::Find", paid: []) }

    before do
      allow(Statements::Find).to receive(:new).and_return(fake_statements_find)

      sign_in_as_admin
    end

    it "calls Statements::Find.paid" do
      get(npq_separation_admin_finance_paid_index_path)

      expect(fake_statements_find).to have_received(:paid).once
    end
  end
end
