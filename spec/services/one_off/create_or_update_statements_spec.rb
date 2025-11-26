require "rails_helper"

RSpec.describe OneOff::CreateOrUpdateStatements do
  describe ".call" do
    let(:cohort_year) { 2021 }
    let(:cohort_identifier) { "#{cohort_year}a" }
    let(:csv_file) { Tempfile.new }
    let(:csv_path) { csv_file.path }

    let(:ambition) { LeadProvider.find_by!(name: "Ambition Institute") }
    let(:cohort) { create(:cohort, start_year: cohort_year) }
    let(:course_1) { create(:course, :senco) }
    let(:course_2) { create(:course, :headship) }
    let(:statement_1) do
      create(:statement,
             year: 2025,
             month: 1,
             cohort: cohort,
             lead_provider: ambition,
             output_fee: true,
             deadline_date: Date.new(2024, 1, 25),
             payment_date: Date.new(2024, 2, 25))
    end
    let(:contract_template_1) { create(:contract_template, per_participant: 100) }
    let(:contract_template_2) { create(:contract_template, per_participant: 200) }

    before do
      csv_file.write(csv_content)
      csv_file.rewind

      create(:contract, contract_template: contract_template_1, statement: statement_1, course: course_1)
      create(:contract, contract_template: contract_template_2, statement: statement_1, course: course_2)

      LeadProvider.where.not(name: "Ambition Institute").map(&:destroy)
    end

    context "when statement can not be found" do
      let(:csv_content) do
        <<~CSV
          name,cohort,deadline_date,payment_date,output_fee
          25-Feb,2021,25/01/2024,25/02/2024,FALSE
        CSV
      end

      it "creates a new statement" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)
        }.to change(Statement, :count).by(1)
      end

      it "creates a new contracts" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)
        }.to change(Contract, :count).by(2)
      end

      it "creates log records" do
        OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)

        statement = Statement.order("created_at DESC").first

        log = FinancialChangeLog.first
        expect(log.operation_description).to eq("OneOff 2326")
        expect(log.data_changes).to eq({ "created_contract_id" => statement.contracts.order("created_at ASC").first.id,
                                         "created_statement_id" => statement.id })

        log = FinancialChangeLog.last
        expect(log.operation_description).to eq("OneOff 2326")
        expect(log.data_changes).to eq({ "created_contract_id" => statement.contracts.order("created_at ASC").last.id,
                                         "created_statement_id" => statement.id })
      end
    end

    context "when statement can be found" do
      let(:csv_content) do
        <<~CSV
          name,cohort,deadline_date,payment_date,output_fee
          25-Jan,2021,25/01/2025,25/02/2025,FALSE
        CSV
      end

      it "updates a statement" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)
        }.to change { statement_1.reload.output_fee }.from(true).to(false)
          .and change(statement_1, :deadline_date).to(Date.new(2025, 1, 25))
          .and change(statement_1, :payment_date).to(Date.new(2025, 2, 25))
      end

      it "creates log records" do
        OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)

        log = FinancialChangeLog.first
        expect(log.operation_description).to eq("OneOff 2520")
        expect(log.data_changes).to eq(
          { "changes" => {
              "output_fee" => [true, false],
              "deadline_date" => %w[2024-01-25 2025-01-25],
              "payment_date" => %w[2024-02-25 2025-02-25],
            },
            "updated_statement_id" => statement_1.id },
        )
      end
    end

    context "when data is incorrect" do
      describe "when date is wrong" do
        let(:csv_content) do
          <<~CSV
            name,cohort,deadline_date,payment_date,output_fee
            25-February,2021,25/01/2024,25/02/2024,FALSE
          CSV
        end

        it "throws an exception" do
          expect {
            OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)
          }.to raise_error(ArgumentError)
        end
      end

      describe "when output_fee is wrong" do
        let(:csv_content) do
          <<~CSV
            name,cohort,deadline_date,payment_date,output_fee
            25-Feb,2021,25/01/2024,25/02/2024,TRU
          CSV
        end

        it "throws an exception" do
          expect {
            OneOff::CreateOrUpdateStatements.new.call(cohort_identifier:, csv_path:)
          }.to raise_error(KeyError)
        end
      end
    end
  end
end
