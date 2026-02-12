class CreateContracts3544RakeTask
  COHORT_IDENTIFIER = "2025b".freeze
  LEAD_PROVIDER_NAME = "Church of England".freeze
  STATEMENTS = [
    # Jan and Feb 2026 statements are payable, so not possible to add a contract to them.
    [2026, 3],
    [2026, 4],
    [2026, 5],
    [2026, 6],
    [2026, 7],
    [2026, 8],
    [2026, 9],
  ].freeze

  include Rake::DSL

  def initialize
    namespace :one_off do
      desc "Add missing contracts as per NPQ-3544 Jira ticket"
      task :add_missing_contracts_3544, %i[recruitment_target per_participant dry_run] => :versioned_environment do |_, args|
        logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)
        dry_run = args[:dry_run] != "false"

        recruitment_target = args[:recruitment_target]
        raise "recruitment_target not specified" unless recruitment_target

        per_participant = args[:per_participant]
        raise "per_participant not specified" unless per_participant

        cohort = Cohort.find_by!(identifier: COHORT_IDENTIFIER)
        lead_provider = LeadProvider.find_by!(name: LEAD_PROVIDER_NAME)

        logger.info "Dry Run" if dry_run
        logger.info "Creating contract template with recruitment_target: #{recruitment_target} and per_participant: #{per_participant}"

        ActiveRecord::Base.transaction do
          contract_template_attributes = {
            "number_of_payment_periods" => 4,
            "service_fee_percentage" => 0,
            "output_payment_percentage" => 100,
            "recruitment_target" => recruitment_target.to_i,
            "service_fee_installments" => 0,
            "per_participant" => per_participant.to_i,
            "special_course" => false,
            "monthly_service_fee" => 0,
          }
          contract_template = ContractTemplate.create!(contract_template_attributes)

          STATEMENTS.each do |year, month|
            statement = Statement.find_by(year: year, month: month, cohort: cohort, lead_provider: lead_provider)

            course = Course.find_by(identifier: "npq-early-headship-coaching-offer")
            contract = Contract.create!(statement:, course: course, contract_template: contract_template)
            logger.info "created contract #{contract.inspect}"
            FinancialChangeLog.log!(description: FinancialChangeLog::ONE_OFF_3544, data: { created_contract_id: contract.id, statement_id: statement.id })
          end

          raise ActiveRecord::Rollback if dry_run
        end
      end
    end
  end
end

CreateContracts3544RakeTask.new
