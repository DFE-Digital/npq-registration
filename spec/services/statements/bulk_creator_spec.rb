# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::BulkCreator do
  include Helpers::StatementsHelper

  let(:cohort)            { create(:cohort) }
  let(:statements_csv_id) { ActiveStorage::Blob.create_and_upload!(io: statements_csv, filename: "statements.csv").signed_id }
  let(:contracts_csv_id)  { ActiveStorage::Blob.create_and_upload!(io: contracts_csv, filename: "contracts.csv").signed_id }

  subject { described_class.new(cohort:, statements_csv_id:, contracts_csv_id:) }

  it { is_expected.to be_valid }

  context "when dry run is false" do
    it "creates statements and contracts" do
      expect { subject.call(dry_run: false) }
        .to change(Statement, :count).by(6)
        .and change(ContractTemplate, :count).by(3)
        .and change(Contract, :count).by(9)

      [
        { lead_provider: LeadProvider.first, cohort:, year: 2025, month: 2, deadline_date: Date.new(2024, 12, 25), payment_date: Date.new(2025, 1, 26), output_fee: true },
        { lead_provider: LeadProvider.first, cohort:, year: 2025, month: 3, deadline_date: Date.new(2025, 1, 26), payment_date: Date.new(2025, 2, 27), output_fee: false },
        { lead_provider: LeadProvider.first, cohort:, year: 2025, month: 4, deadline_date: Date.new(2025, 2, 24), payment_date: Date.new(2025, 3, 25), output_fee: false },
      ].each do |attrs|
        statement = Statement.find_by(attrs)
        expect(statement).to be_present
        expect(statement.contracts.count).to eq(2)
        expect(statement.reconcile_amount).to eq(0)

        contract_template = statement.contracts.find_by(course: Course.first).contract_template
        expect(contract_template.recruitment_target).to eq(30)
        expect(contract_template.per_participant).to eq(1000)
        expect(contract_template.special_course).to be(false)
        expect(contract_template.monthly_service_fee).to eq(100)
        expect(contract_template.service_fee_installments).to eq(12)
        expect(contract_template.number_of_payment_periods).to eq(3)
        expect(contract_template.service_fee_percentage).to eq(40)
        expect(contract_template.output_payment_percentage).to eq(60)

        contract_template = statement.contracts.find_by(course: Course.last).contract_template
        expect(contract_template.recruitment_target).to eq(50)
        expect(contract_template.per_participant).to eq(400)
        expect(contract_template.special_course).to be(true)
        expect(contract_template.monthly_service_fee).to eq(200)
        expect(contract_template.service_fee_installments).to eq(6)
        expect(contract_template.number_of_payment_periods).to eq(4)
        expect(contract_template.service_fee_percentage).to eq(0)
        expect(contract_template.output_payment_percentage).to eq(100)
      end

      [
        { lead_provider: LeadProvider.last, cohort:, year: 2025, month: 2, deadline_date: "2024-12-25", payment_date: "2025-01-26", output_fee: true },
        { lead_provider: LeadProvider.last, cohort:, year: 2025, month: 3, deadline_date: "2025-01-26", payment_date: "2025-02-27", output_fee: false },
        { lead_provider: LeadProvider.last, cohort:, year: 2025, month: 4, deadline_date: "2025-02-24", payment_date: "2025-03-25", output_fee: false },
      ].each do |attrs|
        statement = Statement.find_by(attrs)
        expect(statement).to be_present
        expect(statement.contracts.count).to eq(1)
        expect(statement.reconcile_amount).to eq(0)

        contract_template = statement.contracts.find_by(course: Course.first).contract_template
        expect(contract_template.recruitment_target).to eq(20)
        expect(contract_template.per_participant).to eq(750)
        expect(contract_template.special_course).to be(false)
        expect(contract_template.monthly_service_fee).to eq(0)
        expect(contract_template.service_fee_installments).to eq(9)
        expect(contract_template.number_of_payment_periods).to eq(3)
        expect(contract_template.service_fee_percentage).to eq(40)
        expect(contract_template.output_payment_percentage).to eq(60)
      end
    end
  end

  context "when a statement already exists" do
    before { Statement.create!(cohort:, lead_provider: LeadProvider.last, year: 2025, month: 4) }

    it { is_expected.to have_error :statements_csv, "Statement already exists on line 4" }
  end

  describe "statement CSV" do
    context "when it is not a CSV" do
      let(:statements_csv_id) { ActiveStorage::Blob.create_and_upload!(io: file_fixture("excel_file.xlsx").open, filename: "statements.xlsx").signed_id }

      it { is_expected.to have_error :statements_csv, "must be CSV format" }
    end

    context "with missing headers" do
      let(:statements_csv) do
        tempfile <<~CSV
          year,month,deadline_date
          2024,1,2024-12-25
        CSV
      end

      it { is_expected.to have_error :statements_csv, "Missing headers: payment_date, output_fee" }
    end

    context "with no rows" do
      let(:statements_csv) do
        tempfile <<~CSV
          year,month,deadline_date,payment_date,output_fee
        CSV
      end

      it { is_expected.to have_error :statements_csv, "No rows found" }
    end

    context "with invalid year" do
      let(:statements_csv) do
        tempfile <<~CSV
          year,month,deadline_date,payment_date,output_fee
          1,2,2024-12-25,2025-01-26,true
          foo,3,2025-01-26,2025-02-27,false
          ,4,2025-02-26,2025-03-27,false
        CSV
      end

      it { is_expected.to have_error :statements_csv, "Year must be between 2020 and 2040 on line 2" }
      it { is_expected.to have_error :statements_csv, "Year must be between 2020 and 2040 on line 3" }
      it { is_expected.to have_error :statements_csv, "Year must be between 2020 and 2040 on line 4" }
    end

    context "with invalid month" do
      let(:statements_csv) do
        tempfile <<~CSV
          year,month,deadline_date,payment_date,output_fee
          2024,0,2024-12-25,2025-01-26,true
          2024,13,2024-12-25,2025-01-26,true
          2024,foo,2024-12-25,2025-01-26,true
          2024,,2024-12-25,2025-01-26,true
        CSV
      end

      it { is_expected.to have_error :statements_csv, "Month must be between 1 and 12 on line 2" }
      it { is_expected.to have_error :statements_csv, "Month must be between 1 and 12 on line 3" }
      it { is_expected.to have_error :statements_csv, "Month must be between 1 and 12 on line 4" }
      it { is_expected.to have_error :statements_csv, "Month must be between 1 and 12 on line 5" }
    end

    context "with invalid dates" do
      let(:statements_csv) do
        tempfile <<~CSV
          year,month,deadline_date,payment_date,output_fee
          2025,2,foo,2024-12-01,true
          2025,3,2025-01-01,2024-12-99,true
          2025,4,2025-01-01,,true
        CSV
      end

      it { is_expected.to have_error :statements_csv, "Deadline date must be a date (e.g. YYYY-MM-DD) on line 2" }
      it { is_expected.to have_error :statements_csv, "Payment date must be a date (e.g. YYYY-MM-DD) on line 3" }
      it { is_expected.to have_error :statements_csv, "Payment date must be a date (e.g. YYYY-MM-DD) on line 4" }
    end
  end

  describe "contracts CSV" do
    context "when it is not a CSV" do
      let(:contracts_csv_id) { ActiveStorage::Blob.create_and_upload!(io: file_fixture("excel_file.xlsx").open, filename: "contracts.xlsx").signed_id }

      it { is_expected.to have_error :contracts_csv, "must be CSV format" }
    end

    context "with no rows" do
      let(:contracts_csv) do
        tempfile <<~CSV
          lead_provider_name,course_identifier,recruitment_target,per_participant,special_course,monthly_service_fee,service_fee_installments
        CSV
      end

      it { is_expected.to have_error :contracts_csv, "No rows found" }
    end

    context "with missing headers" do
      let(:contracts_csv) do
        tempfile <<~CSV
          lead_provider_name,course_identifier,recruitment_target,per_participant,special_course,monthly_service_fee
          "#{LeadProvider.first.name}",#{Course.first.identifier},30,1000,false,100
        CSV
      end

      it { is_expected.to have_error :contracts_csv, "Missing headers: service_fee_installments" }
    end

    context "with unknown lead provider" do
      let(:contracts_csv) do
        tempfile <<~CSV
          lead_provider_name,course_identifier,recruitment_target,per_participant,special_course,monthly_service_fee,service_fee_installments
          foobar,#{Course.first.identifier},30,1000,false,100,12
          ,#{Course.first.identifier},30,1000,false,100,12
        CSV
      end

      it { is_expected.to have_error :contracts_csv, "Lead provider name is not recognised on line 2" }
      it { is_expected.to have_error :contracts_csv, "Lead provider name is not recognised on line 3" }
    end

    context "with unknown course identifier" do
      let(:contracts_csv) do
        tempfile <<~CSV
          lead_provider_name,course_identifier,recruitment_target,per_participant,special_course,monthly_service_fee,service_fee_installments
          "#{LeadProvider.first.name}",foo,30,1000,false,100,12
          "#{LeadProvider.first.name}",,30,1000,false,100,12
        CSV
      end

      it { is_expected.to have_error :contracts_csv, "Course identifier is not recognised on line 2" }
      it { is_expected.to have_error :contracts_csv, "Course identifier is not recognised on line 3" }
    end

    context "with invalid numbers" do
      let(:contracts_csv) do
        tempfile <<~CSV
          lead_provider_name,course_identifier,recruitment_target,per_participant,special_course,monthly_service_fee,service_fee_installments
          "#{LeadProvider.first.name}",#{Course.first.identifier},foo,,false,bar,-1
        CSV
      end

      it { is_expected.to have_error :contracts_csv, "Recruitment target is not a number on line 2" }
      it { is_expected.to have_error :contracts_csv, "Per participant is not a number on line 2" }
      it { is_expected.to have_error :contracts_csv, "Monthly service fee is not a number on line 2" }
      it { is_expected.to have_error :contracts_csv, "Service fee installments must be greater than or equal to 0 on line 2" }
    end
  end
end
