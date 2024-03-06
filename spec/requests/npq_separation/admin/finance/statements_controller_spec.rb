require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::StatementsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/statements" do
    let(:fake_statements_find) { instance_double("Statements::Find", all: []) }

    before do
      allow(Statements::Find).to receive(:new).and_return(fake_statements_find)

      sign_in_as_admin
    end

    it "calls Statements::Find.all" do
      get(npq_separation_admin_finance_statements_path)

      expect(fake_statements_find).to have_received(:all).once
    end
  end
end
