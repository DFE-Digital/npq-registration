# frozen_string_literal: true

require "rails_helper"

RSpec.describe NpqSeparation::Admin::Finance::Statements::AssuranceReportsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "#show" do
    subject { response }

    before do
      allow_any_instance_of(AssuranceReports::CsvSerializer).to receive(:filename).and_return("filename.csv")

      declaration
      sign_in_as_admin

      get npq_separation_admin_finance_assurance_report_path(statement, format: :csv)
    end

    let(:lead_provider) { create(:lead_provider) }
    let(:statement)     { create(:statement, lead_provider:) }

    let :declaration do
      travel_to(statement.deadline_date) do
        create(:declaration, lead_provider:) do |declaration|
          create(:statement_item, statement:, declaration:)
        end
      end
    end

    it { is_expected.to have_http_status :success }
    it { is_expected.to have_attributes media_type: /csv/ }
    it { is_expected.to have_attributes body: be_present }

    it "has the correct Content-Disposition header" do
      expect(response.headers["Content-Disposition"]).to eq "attachment; filename=\"filename.csv\"; filename*=UTF-8''filename.csv"
    end
  end
end
