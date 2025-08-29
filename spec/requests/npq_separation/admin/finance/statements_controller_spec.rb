require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::StatementsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  let(:cohort) { create(:cohort, start_year: 2024) }
  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { statements.first }

  let!(:statements) do
    [
      create(:statement, cohort:, lead_provider:, year: 2024, month: 10),
      create(:statement, cohort:, lead_provider:, year: 2024, month: 11),
      create(:statement, cohort:, lead_provider:, year: 2024, month: 12, output_fee: false),
    ]
  end

  before { sign_in_as_admin }

  describe "/npq_separation/admin/statements" do
    subject do
      get(npq_separation_admin_finance_statements_path, params:)
      response
    end

    context "with no params" do
      let(:params) { nil }

      it { is_expected.to have_http_status(:ok) }
    end

    context "with params matching one statement" do
      let(:params) do
        {
          lead_provider_id: statement.lead_provider_id,
          cohort_id: statement.cohort_id,
          statement: "#{statement.year}-#{statement.month}",
        }
      end

      let(:expected_path) { npq_separation_admin_finance_statement_path(statement) }

      it { is_expected.to redirect_to(expected_path) }
    end

    context "with params matching multiple statements" do
      let(:params) do
        {
          lead_provider_id: statement.lead_provider_id,
          cohort_id: statement.cohort_id,
        }
      end

      it { is_expected.to have_http_status(:ok) }
    end

    context "with params matching multiple statements using output fee" do
      let(:params) do
        {
          output_fee: "true",
        }
      end

      it { is_expected.to have_attributes body: %r{October 2024</td>} }
      it { is_expected.to have_attributes body: %r{November 2024</td>} }
      it { is_expected.not_to have_attributes body: %r{December 2024</td>} }
    end

    context "with params matching no statement statement" do
      let(:params) do
        {
          lead_provider_id: statement.lead_provider_id,
          cohort_id: statement.cohort_id,
          statement: "2000-01",
        }
      end

      it { is_expected.to have_http_status(:ok) }
    end
  end

  describe "/npq_separation/admin/statements/{id}" do
    subject do
      get npq_separation_admin_finance_statement_path(statement_id)
      response
    end

    context "when statement exists" do
      let(:statement_id) { statement.id }

      it { is_expected.to have_http_status(:ok) }
    end

    context "when the statement cannot be found", :exceptions_app do
      let(:statement_id) { -1 }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
