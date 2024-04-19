require "rails_helper"

RSpec.describe Statements::Query do
  describe "#statements" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all statements" do
      statement = create(:statement)
      query = Statements::Query.new

      expect(query.statements).to eq([statement])
    end

    it "return only statements with an output fee" do
      create(:statement, output_fee: false)

      query = Statements::Query.new

      expect(query.statements).to be_empty
    end

    it "orders statements by payment date in ascending order" do
      statement1 = create(:statement, payment_date: 2.days.ago)
      statement2 = create(:statement, payment_date: 1.day.ago)
      statement3 = create(:statement, payment_date: Time.zone.now)

      query = Statements::Query.new

      expect(query.statements).to eq([statement1, statement2, statement3])
    end

    describe "filtering" do
      describe "by lead provider" do
        it "filters by lead provider" do
          statement = create(:statement, lead_provider:)
          _statement = create(:statement)
          query = Statements::Query.new(lead_provider:)

          expect(query.statements).to eq([statement])
        end

        it "does not return statements for other Lead Providers" do
          other_lead_provider = create(:lead_provider)
          create(:statement, lead_provider: other_lead_provider)

          query = Statements::Query.new(lead_provider:)

          expect(query.statements).to eq([])
        end
      end

      describe "by cohort" do
        let!(:cohort_2023) { create(:cohort, start_year: 2023) }
        let!(:cohort_2024) { create(:cohort, start_year: 2024) }
        let!(:cohort_2025) { create(:cohort, start_year: 2025) }

        it "filters by cohort" do
          _statement = create(:statement, cohort: cohort_2023)
          statement = create(:statement, cohort: cohort_2024)
          query = Statements::Query.new(cohort_start_years: "2024")

          expect(query.statements).to eq([statement])
        end

        it "filters by multiple cohorts" do
          statement1 = create(:statement, cohort: cohort_2023)
          statement2 = create(:statement, cohort: cohort_2024)
          _statement = create(:statement, cohort: cohort_2025)
          query = Statements::Query.new(cohort_start_years: "2023,2024")

          expect(query.statements).to match_array([statement1, statement2])
        end

        it "returns no statements if no cohorts are found" do
          query = Statements::Query.new(cohort_start_years: "0000")

          expect(query.statements).to be_empty
        end
      end

      describe "by updated_since" do
        let(:updated_since) { 1.day.ago }

        it "filters by updated since" do
          create(:statement, lead_provider:, updated_at: 2.days.ago)
          statement2 = create(:statement, lead_provider:, updated_at: Time.zone.now)

          query = Statements::Query.new(lead_provider:, updated_since:)

          expect(query.statements).to eq([statement2])
        end
      end

      describe "by state" do
        let!(:open_statement) { create(:statement, :open) }
        let!(:payable_statement) { create(:statement, :payable) }
        let!(:paid_statement) { create(:statement, :paid) }

        it "filters by state" do
          expect(Statements::Query.new(state: "open").statements).to eq([open_statement])
          expect(Statements::Query.new(state: "payable").statements).to eq([payable_statement])
          expect(Statements::Query.new(state: "paid").statements).to eq([paid_statement])
        end

        it "filters by multiple states" do
          expect(Statements::Query.new(state: "open,paid").statements).to match_array([open_statement, paid_statement])
        end

        xit "raises when invalid states queried" do
          expect { Statements::Query.new(state: "error").statements }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#statement" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns the statement for a Lead Provider" do
      statement = create(:statement, lead_provider:)
      query = Statements::Query.new

      expect(query.statement(ecf_id: statement.ecf_id)).to eq(statement)
      expect(query.statement(id: statement.id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = Statements::Query.new

      expect { query.statement(ecf_id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.statement(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_statement = create(:statement, lead_provider: other_lead_provider)

      query = Statements::Query.new(lead_provider:)

      expect { query.statement(ecf_id: other_statement.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.statement(id: other_statement.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if neither an ecf_id or id is supplied" do
      expect { Statements::Query.new.statement }.to raise_error(ArgumentError, "id or ecf_id needed")
    end
  end
end
