require "rails_helper"

RSpec.describe Statements::Query do
  describe "#statements" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all statements" do
      statement = create(:statement)
      query = described_class.new

      expect(query.statements).to eq([statement])
    end

    it "orders statements by payment date in ascending order" do
      statement1 = create(:statement, payment_date: 2.days.ago)
      statement2 = create(:statement, payment_date: 1.day.ago)
      statement3 = create(:statement, payment_date: Time.zone.now)

      query = described_class.new

      expect(query.statements).to eq([statement1, statement2, statement3])
    end

    context "when statement has multiple associated records" do
      let!(:statement1) { create(:statement) }
      let!(:statement2) { create(:statement) }

      before do
        create(:statement_item, statement: statement1)
        create(:statement_item, statement: statement1)
        create(:contract, course: create(:course, :senior_leadership), statement: statement1)
        create(:contract, course: create(:course, :leading_literacy), statement: statement1)
      end

      it "does not return duplicate statements" do
        query = described_class.new
        expect(query.statements).to contain_exactly(statement1, statement2)
      end
    end

    describe "filtering" do
      describe "by lead provider" do
        it "filters by lead provider" do
          statement = create(:statement, lead_provider:)
          _statement = create(:statement)
          query = described_class.new(lead_provider:)

          expect(query.statements).to eq([statement])
        end

        it "does not return statements for other Lead Providers" do
          create(:statement, lead_provider: LeadProvider.where.not(id: lead_provider.id).first)

          query = described_class.new(lead_provider:)

          expect(query.statements).to eq([])
        end

        it "does not filter by lead provider if none is supplied" do
          condition_string = %("lead_provider_id")
          query = described_class.new

          expect(query.scope.to_sql).not_to include(condition_string)
        end

        it "does not filter by lead provider if an empty string is supplied" do
          condition_string = %("lead_provider_id")
          query = described_class.new(lead_provider: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "by cohort" do
        let!(:cohort_2023) { create(:cohort, start_year: 2023) }
        let!(:cohort_2024) { create(:cohort, start_year: 2024) }
        let!(:cohort_2025) { create(:cohort, start_year: 2025) }

        context "when cohort param omitted" do
          it "returns all statements" do
            statement1 = FactoryBot.create(:statement, cohort: cohort_2023)
            statement2 = FactoryBot.create(:statement, cohort: cohort_2024)
            statement3 = FactoryBot.create(:statement, cohort: cohort_2025)

            expect(described_class.new.statements).to contain_exactly(statement1, statement2, statement3)
          end

          it "doesn't reference the cohort's start_year in the query" do
            column_name = %("cohort"."start_year")

            expect(described_class.new.scope.to_sql).not_to include(column_name)
            expect(described_class.new(cohort_start_years: "2021").scope.to_sql).to include(column_name)
          end
        end

        it "filters by cohort" do
          _statement = create(:statement, cohort: cohort_2023)
          statement = create(:statement, cohort: cohort_2024)
          query = described_class.new(cohort_start_years: "2024")

          expect(query.statements).to eq([statement])
        end

        it "filters by multiple cohorts" do
          statement1 = create(:statement, cohort: cohort_2023)
          statement2 = create(:statement, cohort: cohort_2024)
          statement3 = create(:statement, cohort: cohort_2025)

          query1 = described_class.new(cohort_start_years: "2023,2024")
          expect(query1.statements).to contain_exactly(statement1, statement2)

          query2 = described_class.new(cohort_start_years: %w[2024 2025])
          expect(query2.statements).to contain_exactly(statement2, statement3)
        end

        it "returns no statements if no cohorts are found" do
          query = described_class.new(cohort_start_years: "0000")

          expect(query.statements).to be_empty
        end

        it "does not filter by cohort if blank" do
          condition_string = %("start_year")
          query = described_class.new(cohort_start_years: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "by updated_since" do
        let(:updated_since) { 1.day.ago }

        it "filters by updated since" do
          create(:statement, lead_provider:, updated_at: 2.days.ago)
          statement2 = create(:statement, lead_provider:, updated_at: Time.zone.now)

          query = described_class.new(lead_provider:, updated_since:)

          expect(query.statements).to eq([statement2])
        end

        context "when updated_since param omitted" do
          it "returns all statements" do
            statement1 = FactoryBot.create(:statement, updated_at: 1.week.ago)
            statement2 = FactoryBot.create(:statement, updated_at: 2.weeks.ago)

            expect(described_class.new.statements).to contain_exactly(statement1, statement2)
          end

          it "doesn't reference updated_at in the query" do
            column_name = %("updated_at")

            expect(described_class.new.scope.to_sql).not_to include(column_name)
            expect(described_class.new(updated_since: 1.day.ago).scope.to_sql).to include(column_name)
          end
        end

        it "does not filter by updated_since if blank" do
          condition_string = %("updated_at")
          query = described_class.new(updated_since: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "by state" do
        let!(:open_statement) { create(:statement, :open) }
        let!(:payable_statement) { create(:statement, :payable) }
        let!(:paid_statement) { create(:statement, :paid) }

        it "filters by state" do
          expect(described_class.new(state: "open").statements).to eq([open_statement])
          expect(described_class.new(state: "payable").statements).to eq([payable_statement])
          expect(described_class.new(state: "paid").statements).to eq([paid_statement])
        end

        it "filters by multiple states with a comma separated list" do
          expect(described_class.new(state: "open,paid").statements).to contain_exactly(open_statement, paid_statement)
        end

        it "filters by multiple states with an array" do
          expect(described_class.new(state: %w[open paid]).statements).to contain_exactly(open_statement, paid_statement)
        end

        it "raises when invalid states queried", pending: "needs implementation" do
          expect { described_class.new(state: "error").statements }.to raise_error(ArgumentError)
        end

        context "when state param omitted" do
          it "returns all statements" do
            expect(described_class.new.statements).to contain_exactly(open_statement, payable_statement, paid_statement)
          end

          it "doesn't reference the state in the query" do
            column_name = %("state")

            expect(described_class.new.scope.to_sql).not_to include(column_name)
            expect(described_class.new(state: "open").scope.to_sql).to include(column_name)
          end
        end

        it "does not filter by state if blank" do
          condition_string = %("state")
          query = described_class.new(state: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end

      describe "by output fee" do
        it "return only statements with an output fee by default" do
          create(:statement, output_fee: false)

          query = described_class.new

          expect(query.statements).to be_empty
        end

        context "when output_fee: false" do
          it "return only statements with an output fee by default" do
            output_fee = create(:statement, output_fee: false)

            query = described_class.new(output_fee: false)

            expect(query.statements).to include(output_fee)
          end
        end

        context "when output_fee: :ignore" do
          it "returns all statements" do
            statement1 = FactoryBot.create(:statement, output_fee: true)
            statement2 = FactoryBot.create(:statement, output_fee: false)

            expect(described_class.new(output_fee: :ignore).statements).to contain_exactly(statement1, statement2)
          end

          it "doesn't reference the output_fee in the query" do
            column_name = %("output_fee")

            expect(described_class.new.scope.to_sql).to include(column_name)
            expect(described_class.new(output_fee: :ignore).scope.to_sql).not_to include(column_name)
          end
        end

        it "does not filter by output_fee if blank" do
          condition_string = %("output_fee")
          query = described_class.new(output_fee: " ")

          expect(query.scope.to_sql).not_to include(condition_string)
        end
      end
    end
  end

  describe "#statement" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns the statement for a Lead Provider" do
      statement = create(:statement, lead_provider:)
      query = described_class.new

      expect(query.statement(ecf_id: statement.ecf_id)).to eq(statement)
      expect(query.statement(id: statement.id)).to eq(statement)
    end

    it "raises an error if the statement does not exist" do
      query = described_class.new

      expect { query.statement(ecf_id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.statement(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the statement is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_statement = create(:statement, lead_provider: other_lead_provider)

      query = described_class.new(lead_provider:)

      expect { query.statement(ecf_id: other_statement.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.statement(id: other_statement.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if neither an ecf_id or id is supplied" do
      expect { described_class.new.statement }.to raise_error(ArgumentError, "id or ecf_id needed")
    end
  end
end
