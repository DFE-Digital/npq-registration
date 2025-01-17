require "rails_helper"

RSpec.describe "one_off:create_contract" do
  let(:csv_file) { Tempfile.new }
  let(:csv_file_path) { csv_file.path }
  let(:lead_provider_name) { "LLSE" }

  before do
    create(:statement, year: 2025, month: 1, cohort: create(:cohort, start_year: 2023), lead_provider: LeadProvider.find_by(name: lead_provider_name))
    csv_file.write("provider_name,cohort_year,course_identifier,recruitment_target,service_fee_installments,service_fee_percentage,per_participant,number_of_payment_periods,output_payment_percentage,monthly_service_fee,targeted_delivery_funding_per_participant,special_course\n")
    csv_file.write("#{lead_provider_name},2023,npq-early-headship-coaching-offer,7,0,1,800,4,100,10,90,TRUE\n")
    csv_file.rewind
  end

  after do
    Rake::Task["one_off:create_contract"].reenable
  end

  context "when dry run not specified" do
    subject(:run_task) { Rake::Task["one_off:create_contract"].invoke(csv_file_path) }

    it "does not create a contract or contract template" do
      run_task
      expect(Contract.count).to eq 0
      expect(ContractTemplate.count).to eq 0
    end
  end

  context "when dry run true" do
    subject(:run_task) { Rake::Task["one_off:create_contract"].invoke(csv_file_path, "true") }

    it "does not create a contract or contract template" do
      run_task
      expect(Contract.count).to eq 0
      expect(ContractTemplate.count).to eq 0
    end
  end

  context "when dry run false" do
    subject(:run_task) { Rake::Task["one_off:create_contract"].invoke(csv_file_path, "false") }

    it "creates a contract" do
      expect { run_task }.to change(Contract, :all).from([]).to a_collection_containing_exactly(
        an_object_having_attributes(
          course: Course.find_by(identifier: "npq-early-headship-coaching-offer"),
          statement: Statement.find_by(year: 2025, month: 1),
        ),
      )
    end

    it "creates a contract template" do
      expect { run_task }.to change(ContractTemplate, :all).from([]).to a_collection_containing_exactly(
        an_object_having_attributes(
          recruitment_target: 7,
          service_fee_installments: 0,
          service_fee_percentage: 1,
          per_participant: 800,
          number_of_payment_periods: 4,
          output_payment_percentage: 100,
          monthly_service_fee: 10,
          targeted_delivery_funding_per_participant: 90,
          special_course: true,
        ),
      )
    end

    context "when the contract has already been created" do
      before do
        create(:contract, course: Course.find_by(identifier: "npq-early-headship-coaching-offer"), statement: Statement.find_by(year: 2025, month: 1))
      end

      it "exits with error code 1" do
        expect { run_task }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
      end
    end
  end

  context "when the CSV file is not found" do
    subject(:run_task) { Rake::Task["one_off:create_contract"].execute(file: "nonexistent_file") }

    it "exits with error code 1" do
      expect { run_task }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end
  end
end
