require "rails_helper"

RSpec.describe "one_off:add_missing_contracts_3544" do
  let(:cohort) { create(:cohort, start_year: 2025, identifier: "2025b", suffix: "b") }
  let(:lead_provider) { LeadProvider.find_by(name: CreateContracts3544RakeTask::LEAD_PROVIDER_NAME) }
  let(:course) { create(:course, :early_headship_coaching_offer) }

  before do
    course
    (3..9).each do |month|
      create(:statement, year: 2026, month:, cohort:, lead_provider:)
    end
  end

  after do
    Rake::Task["one_off:add_missing_contracts_3544"].reenable
  end

  context "when dry run false" do
    subject(:run_task) { Rake::Task["one_off:add_missing_contracts_3544"].invoke(10, 100, "false") }

    it "creates contracts" do
      expect { run_task }.to change { Contract.all.to_a }.from([]).to match_array(
        (3..9).map do |month|
          an_object_having_attributes(
            course_id: course.id,
            statement_id: Statement.find_by(year: 2026, month:).id,
          )
        end,
      )
    end

    it "creates a contract template" do
      expect { run_task }.to change(ContractTemplate, :all).from([]).to a_collection_containing_exactly(
        an_object_having_attributes(
          recruitment_target: 10,
          service_fee_installments: 0,
          service_fee_percentage: 0,
          per_participant: 100,
          number_of_payment_periods: 4,
          output_payment_percentage: 100,
          monthly_service_fee: 0,
          special_course: false,
        ),
      )
    end

    it "creates a financial change log entry for each contract created" do
      run_task
      expect(FinancialChangeLog.all.to_a).to match_array(
        Contract.all.map do |contract|
          an_object_having_attributes(
            operation_description: FinancialChangeLog::ONE_OFF_3544,
            data_changes: { "created_contract_id" => contract.id, "statement_id" => contract.statement_id },
          )
        end,
      )
    end

    context "when the recruitment_target parameter is missing" do
      subject(:run_task) { Rake::Task["one_off:add_missing_contracts_3544"].invoke }

      it { expect { run_task }.to raise_exception "recruitment_target not specified" }
    end

    context "when the per_participant parameter is missing" do
      subject(:run_task) { Rake::Task["one_off:add_missing_contracts_3544"].invoke(10) }

      it { expect { run_task }.to raise_exception "per_participant not specified" }
    end
  end

  context "when dry run true" do
    subject(:run_task) { Rake::Task["one_off:add_missing_contracts_3544"].invoke(10, 100) }

    it "does not create contracts" do
      expect { run_task }.not_to change(Contract, :count)
    end

    it "does not create a contract template" do
      expect { run_task }.not_to change(ContractTemplate, :count)
    end

    it "does not create financial change log entries" do
      expect { run_task }.not_to change(FinancialChangeLog, :count)
    end
  end
end
