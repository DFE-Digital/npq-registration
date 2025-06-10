require "rails_helper"

RSpec.describe "one_off:create_contract" do
  let(:csv_file) { Tempfile.new }
  let(:csv_file_path) { csv_file.path }
  let(:lead_provider_name) { "UCL Institute of Education" }
  let(:year) { 2025 }
  let(:month) { 8 }

  before do
    create(:statement, year: year, month: month, cohort: create(:cohort, start_year: 2025), lead_provider: LeadProvider.find_by(name: lead_provider_name))
    create(:course, :early_headship_coaching_offer)
    csv_file.write("lead_provider_name,course_identifier,recruitment_target,per_participant,service_fee_installments,special_course,monthly_service_fee\n")
    csv_file.write("#{lead_provider_name},npq-early-headship-coaching-offer,5,25,0,FALSE,0\n")
    csv_file.rewind

    stub_const("OneOff::MISSING_CONTRACTS_DATES_2896", [[year, month]])
  end

  after do
    Rake::Task["one_off:add_missing_contracts_2896"].reenable
  end

  context "when dry run false" do
    subject(:run_task) { Rake::Task["one_off:add_missing_contracts_2896"].invoke(csv_file_path, "false") }

    it "creates a contract" do
      expect { run_task }.to change(Contract, :all).from([]).to a_collection_containing_exactly(
        an_object_having_attributes(
          course: Course.find_by(identifier: "npq-early-headship-coaching-offer"),
          statement: Statement.find_by(year: year, month: month),
        ),
      )
    end

    it "creates a contract template" do
      expect { run_task }.to change(ContractTemplate, :all).from([]).to a_collection_containing_exactly(
        an_object_having_attributes(
          recruitment_target: 5,
          service_fee_installments: 0,
          service_fee_percentage: 0,
          per_participant: 25,
          number_of_payment_periods: 4,
          output_payment_percentage: 100,
          monthly_service_fee: 0,
          special_course: false,
        ),
      )
    end
  end
end
