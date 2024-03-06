require "rails_helper"

RSpec.describe Statements::StatementsQuery do
  describe "#statements" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all statements for a provider" do
      _statement = create(:statement)
      statement = create(:statement, lead_provider:)
      query = Statements::StatementsQuery.new(
        lead_provider:,
        params: {},
      )

      expect(query.statements).to eq([statement])
    end

    describe "filtering" do
      describe "by updated since" do
        let(:updated_since) { 1.day.ago }
        let!(:statement1) { create(:statement, lead_provider: lead_provider, updated_at: 2.days.ago) }
        let!(:statement2) { create(:statement, lead_provider: lead_provider, updated_at: Time.now) }

        it "filters by updated since" do
          query = Statements::StatementsQuery.new(
            lead_provider: lead_provider,
            params: { updated_since: updated_since },
          )

          expect(query.statements).to eq([statement2])
        end
      end
      describe "by cohort" do
        let(:cohort_2023) { create(:cohort, start_year: 2023) }
        let(:cohort_2024) { create(:cohort, start_year: 2024) }
        let(:cohort_2025) { create(:cohort, start_year: 2025) }

        it "filters by cohort" do
          _statement = create(:statement, lead_provider:, cohort: cohort_2023)
          statement = create(:statement, lead_provider:, cohort: cohort_2024)
          query = Statements::StatementsQuery.new(
            lead_provider:,
            params: { cohort: "2024" },
          )

          expect(query.statements).to eq([statement])
        end

        it "filters by multiple cohorts" do
          statement1 = create(:statement, lead_provider:, cohort: cohort_2023)
          statement2 = create(:statement, lead_provider:, cohort: cohort_2024)
          _statement = create(:statement, lead_provider:, cohort: cohort_2025)
          query = Statements::StatementsQuery.new(
            lead_provider:,
            params: { cohort: "2023,2024" },
          )

          expect(query.statements).to match_array([statement1, statement2])
        end

        it "returns no statements if no cohorts are found" do
          query = Statements::StatementsQuery.new(
            lead_provider:,
            params: { cohort: "9999" },
          )

          expect(query.statements).to be_empty
        end
      end
    end
  end
end
