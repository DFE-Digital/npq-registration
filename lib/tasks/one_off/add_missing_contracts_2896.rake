module OneOff
  MISSING_CONTRACTS_DATES_2896 = [
    [2025, 1],
    [2025, 2],
    [2025, 3],
    [2025, 4],
    [2025, 5],
    [2025, 6],
    # July 2025 is already created
    [2025, 8],
    [2025, 9],
    [2025, 10],
    [2025, 11],
    [2025, 12],
    # January 2026 is already created
    [2026, 2],
    [2026, 3],
    [2026, 4],
    [2026, 5],
    [2026, 6],
    [2026, 7],
    [2026, 8],
    [2026, 9],
    [2026, 10],
    [2026, 11],
    [2026, 12],
    [2027, 1],
    [2027, 2],
    [2027, 3],
    [2027, 4],
    [2027, 5],
    [2027, 6],
    [2027, 7],
  ].freeze
end

namespace :one_off do
  desc "Add missing contract data as per 2896 JIRA ticket"
  task :add_missing_contracts_2896, %i[csv_file_path] => :environment do |_task, args|
    cohort = Cohort.find_by!(start_year: 2025)
    lead_provider = LeadProvider.find_by!(name: "UCL Institute of Education")
    row = CSV.read(args["csv_file_path"], headers: true).first
    ActiveRecord::Base.transaction do
      OneOff::MISSING_CONTRACTS_DATES_2896.each do |year, month|
        statements = Statement.where(year: year, month: month, cohort: cohort, lead_provider: lead_provider)
        raise if statements.count != 1

        course = Course.find_by(identifier: "npq-early-headship-coaching-offer")
        contract_template_attributes = {
          "number_of_payment_periods" => 4,
          "service_fee_percentage" => 0,
          "output_payment_percentage" => 100,
          "recruitment_target" => row["recruitment_target"],
          "service_fee_installments" => row["service_fee_installments"],
          "per_participant" => row["per_participant"],
          "special_course" => false,
          "monthly_service_fee" => row["monthly_service_fee"],
        }
        contract_template = ContractTemplate.create!(contract_template_attributes)
        contract = Contract.create!(statement: statements.first, course: course, contract_template: contract_template)
        FinancialChangeLog.log!(description: FinancialChangeLog::ONE_OFF_2896, data: { created_contract_id: contract.id, statement_id: statements.first.id })
      end
    end
  end
end
