namespace :one_off do
  desc "One off task for ticket NPQ-3678 to update statement and move declarations"
  task :update_statement_move_declarations, %i[dry_run] => :versioned_environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    dry_run = args[:dry_run] != "false"

    Rails.logger.info "DRY RUN: will roll back at end" if dry_run

    ActiveRecord::Base.transaction do
      lead_providers = LeadProvider.active

      lead_providers.each do |lead_provider|
        statement = Statement.find_by(
          month: 9,
          year: 2026,
          cohort: Cohort.find_by!(identifier: "2025a"),
          lead_provider:,
        )
        statement.update!(output_fee: true)

        Rails.logger.info "Set output_fee: true on #{statement.month}/#{statement.year} statement, cohort: #{statement.cohort.identifier}, lead provider: #{statement.lead_provider.name}"
      end

      leadership_course_identifiers = %w[
        npq-early-years-leadership
        npq-executive-leadership
        npq-headship
        npq-senco
        npq-senior-leadership
      ]

      Rails.logger.info "Move retained-2 leadership declarations from July 2026 to August 2026 for 2025a cohort"

      migrator = OneOff::MigrateDeclarationsBetweenStatements
        .new(
          from_year: 2026,
          from_month: 7,
          to_year: 2026,
          to_month: 8,
          cohort: Cohort.find_by!(identifier: "2025a"),
          override_date_checks: true,
          restrict_to_course_identifiers: leadership_course_identifiers,
          restrict_to_declaration_types: "retained-2",
        )

      unless migrator.migrate(dry_run:)
        Rails.logger.info "Validation failure:"
        Rails.logger.info migrator.errors.full_messages.to_yaml
      end

      if dry_run
        Rails.logger.info "DRY RUN: rolling back transaction"
        raise ActiveRecord::Rollback
      end
    end
  end
end
