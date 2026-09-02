namespace :one_off do
  desc "One off task for ticket NPQ-3979 to update statement"
  task :update_statement_2025a_oct26, %i[dry_run] => :versioned_environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    dry_run = args[:dry_run] != "false"

    Rails.logger.info "DRY RUN: will roll back at end" if dry_run

    ActiveRecord::Base.transaction do
      lead_providers = LeadProvider.active

      lead_providers.each do |lead_provider|
        statement = Statement.find_by(
          month: 10,
          year: 2026,
          cohort: Cohort.find_by!(identifier: "2025a"),
          lead_provider:,
        )
        statement.update!(output_fee: true)

        Rails.logger.info "Set output_fee: true on #{statement.month}/#{statement.year} statement, " \
          "cohort: #{statement.cohort.identifier}, lead provider: #{statement.lead_provider.name}"
      end

      if dry_run
        Rails.logger.info "DRY RUN: rolling back transaction"
        raise ActiveRecord::Rollback
      end
    end
  end
end
