require "rails_helper"

RSpec.describe Statements::Query do
  let(:lead_provider) { create(:lead_provider) }

  describe "#statements" do
    it "returns all statements for a Lead Provider" do
      statement = create(:statement, lead_provider:)
      query = Statements::Query.new
                               .belonging_to(lead_provider:)

      expect(query.statements).to eq([statement])
    end

    it "does not return statements for other Lead Providers" do
      other_lead_provider = create(:lead_provider)
      create(:statement, lead_provider: other_lead_provider)

      query = Statements::Query.new
                               .belonging_to(lead_provider:)

      expect(query.statements).to eq([])
    end

    describe "filtering" do
      describe "by cohort" do
        let!(:cohort_2023) { create(:cohort, start_year: 2023) }
        let!(:cohort_2024) { create(:cohort, start_year: 2024) }
        let!(:cohort_2025) { create(:cohort, start_year: 2025) }

        it "filters by cohort" do
          _statement = create(:statement, lead_provider:, cohort: cohort_2023)
          statement = create(:statement, lead_provider:, cohort: cohort_2024)
          query = Statements::Query.new
                                   .belonging_to(lead_provider:)
                                   .by_cohorts(2024)

          expect(query.statements).to eq([statement])
        end

        it "filters by multiple cohorts" do
          statement1 = create(:statement, lead_provider:, cohort: cohort_2023)
          statement2 = create(:statement, lead_provider:, cohort: cohort_2024)
          _statement = create(:statement, lead_provider:, cohort: cohort_2025)
          query = Statements::Query.new
                                   .belonging_to(lead_provider:)
                                   .by_cohorts(2024, 2023)

          expect(query.statements).to match_array([statement1, statement2])
        end

        it "returns no statements if no cohorts are found" do
          query = Statements::Query.new
                                   .belonging_to(lead_provider:)
                                   .by_cohorts(0)

          expect(query.statements).to be_empty
        end
      end

      describe "by updated_since" do
        let(:updated_since) { 1.day.ago }

        it "filters by updated since" do
          create(:statement, lead_provider:, updated_at: 2.days.ago)
          statement2 = create(:statement, lead_provider:, updated_at: Time.zone.now)

          query = Statements::Query.new
                                   .belonging_to(lead_provider:)
                                   .updated_since(updated_since)

          expect(query.statements).to eq([statement2])
        end
      end
    end
  end

  describe "#statement" do
    it "returns the statement for a Lead Provider" do
      statement = create(:statement, lead_provider:)
      query = Statements::Query.new
                               .belonging_to(lead_provider:)

      expect(query.statement(id: statement.id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = Statements::Query.new
                               .belonging_to(lead_provider:)

      expect { query.statement(id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement belong to other Lead Provider" do
      other_lead_provider = create(:lead_provider)
      other_statement = create(:statement, lead_provider: other_lead_provider)

      query = Statements::Query.new
                               .belonging_to(lead_provider:)

      expect { query.statement(id: other_statement.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
