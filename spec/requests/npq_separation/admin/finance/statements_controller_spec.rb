require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::StatementsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/statements" do
    before do
      allow(Statements::Query).to receive(:new).and_call_original

      sign_in_as_admin
    end

    it "calls Statements::Query.all" do
      get(npq_separation_admin_finance_statements_path)

      expect(Statements::Query).to have_received(:new).with(no_args).once
    end
  end
end
