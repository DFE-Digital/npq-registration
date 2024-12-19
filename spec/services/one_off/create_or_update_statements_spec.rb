require "rails_helper"

RSpec.describe OneOff::CreateOrUpdateStatements do
  describe ".call" do
    let(:year) { 2024 }
    let(:month) { 12 }
    let(:cohort_year) { 2021 }
    let(:csv_file) { Tempfile.new }
    let(:csv_path) { csv_file.path }

    let(:ambition) { LeadProvider.find_by!(name: "Ambition Institute") }
    let(:cohort) { create(:cohort, start_year: cohort_year) }
    let(:course_1) { create(:course, :senco) }
    let(:course_2) { create(:course, :headship) }
    let(:statement_1) { create(:statement, year: 2025, month: 1, cohort: cohort, lead_provider: ambition, output_fee: true) }
    let(:contract_template_1) { create(:contract_template, per_participant: 100) }
    let(:contract_template_2) { create(:contract_template, per_participant: 200) }
    let(:contract_1) { create(:contract, contract_template: contract_template_1, statement: statement_1, course: course_1) }
    let(:contract_2) { create(:contract, contract_template: contract_template_2, statement: statement_1, course: course_2) }

    before do
      csv_file.write(csv_content)
      csv_file.rewind

      contract_1
      contract_2
    end

    context "when statement can not be found" do
      let(:csv_content) do
        <<~CSV
          name,cohort,deadline_date,payment_date,output_fee
          25-Feb,2021,25/01/2024,25/02/2024,FALSE
        CSV
      end

      before do
        LeadProvider.where.not(name: "Ambition Institute").map(&:destroy)
      end

      it "creates a new statement" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path:)
        }.to change(Statement, :count).by(1)
      end

      it "creates a new contracts" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path:)
        }.to change(Contract, :count).by(2)
      end

      it "creates log records" do
        OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path:)

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
          25-Jan,2021,25/01/2024,25/02/2024,FALSE
        CSV
      end

      before do
        LeadProvider.where.not(name: "Ambition Institute").map(&:destroy)
      end

      it "updates a statement" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path:)
        }.to change { statement_1.reload.output_fee }.from(true).to(false)
      end

      it "creates log records" do
        OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path:)

        log = FinancialChangeLog.first
        expect(log.operation_description).to eq("OneOff 2326")
        expect(log.data_changes).to eq({ "updated_statement_id" => statement_1.id })
      end
    end

    context "when data is incorrect" do
      let(:csv_content) do
        <<~CSV
          name,cohort,deadline_date,payment_date,output_fee
          25-February,2021,25/01/2024,25/02/2024,FALSE
        CSV
      end

      it "updates a statement" do
        expect {
          OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path:)
        }.to raise_error(ArgumentError)
      end
    end
  end
end
