namespace :one_off do
  desc "Move UCL declarations from January 2026 to June 2025 for 2025 Cohort"
  task :move_declarations_from_jan26_to_jun25, %i[dry_run override_date_checks] => :environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    Rails.logger.level = Logger::INFO
    dry_run = args[:dry_run] != "false"
    override_date_checks = args[:override_date_checks] == "true"

    cohort = Cohort.find_by!(start_year: 2025)
    lead_provider = LeadProvider.find_by!(name: "UCL Institute of Education")

    migrator = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 1,
        to_year: 2025,
        to_month: 6,
        cohort:,
        override_date_checks:,
        restrict_to_lead_providers: lead_provider,
        restrict_to_course_identifiers: "npq-early-headship-coaching-offer",
      )

    unless migrator.migrate(dry_run:)
      Rails.logger.info "Validation failure:"
      Rails.logger.info migrator.errors.full_messages.to_yaml
    end
  end
end
