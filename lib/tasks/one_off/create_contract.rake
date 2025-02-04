class CreateContractRakeTask
  COHORT_YEAR = 2023
  STATEMENT_YEAR = 2025
  FEBRUARY = 2
  STATEMENT_MONTH = FEBRUARY
  LEAD_PROVIDER_NAME = "LLSE".freeze

  include Rake::DSL

  def initialize
    namespace :one_off do
      # Example usage (dry run):
      # bundle exec rake 'one_off:create_contract[tmp/contract.csv]'
      #
      # Example usage (perform change):
      # bundle exec rake 'one_off:create_contract[tmp/contract.csv,false]'
      desc "One off task for ticket CPDNPQ-2538 to create missing contract"
      task :create_contract, %i[file dry_run] => :environment do |_t, args|
        logger = Logger.new($stdout)
        dry_run = args[:dry_run] != "false"
        csv_file_path = args[:file]

        unless File.exist?(csv_file_path)
          logger.error "File not found: #{csv_file_path}"
          exit 1
        end

        row = CSV.read(csv_file_path, headers: true).first
        statement = Statement.find_by(year: STATEMENT_YEAR, month: STATEMENT_MONTH, cohort: Cohort.find_by(start_year: COHORT_YEAR), lead_provider: LeadProvider.find_by(name: LEAD_PROVIDER_NAME))
        course = Course.find_by(identifier: row["course_identifier"])

        if Contract.where(course: course, statement: statement).exists?
          logger.error "Contract already exists for course #{course.identifier} and statement #{statement.id}"
          exit 1
        end

        logger.info "Dry Run" if dry_run

        ActiveRecord::Base.transaction do
          contract_template = ContractTemplate.create!(
            special_course: row["special_course"],
            per_participant: row["per_participant"],
            output_payment_percentage: row["output_payment_percentage"],
            number_of_payment_periods: row["number_of_payment_periods"],
            service_fee_percentage: row["service_fee_percentage"],
            service_fee_installments: row["service_fee_installments"],
            recruitment_target: row["recruitment_target"],
            monthly_service_fee: row["monthly_service_fee"],
            targeted_delivery_funding_per_participant: row["targeted_delivery_funding_per_participant"],
          )
          logger.info "created #{contract_template.inspect}"

          contract = statement.contracts.create!(course:, contract_template:)
          logger.info "created contract #{contract.inspect}"

          raise ActiveRecord::Rollback if dry_run
        end
      end
    end
  end
end
CreateContractRakeTask.new
