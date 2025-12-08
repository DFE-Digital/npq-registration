namespace :one_off do
  desc "Move declarations from July 2025 to June 2025 for 2022 Cohort"
  task :move_declarations_from_jul25_to_jun25, %i[dry_run override_date_checks] => :environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    Rails.logger.level = Logger::INFO
    dry_run = args[:dry_run] != "false"
    override_date_checks = args[:override_date_checks] == "true"

    cohort = Cohort.find_by!(identifier: "2022a")

    migrator = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2025,
        from_month: 7,
        to_year: 2025,
        to_month: 6,
        cohort:,
        from_statement_updates: { output_fee: false },
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    unless migrator.migrate(dry_run:)
      Rails.logger.info "Validation failure:"
      Rails.logger.info migrator.errors.full_messages.to_yaml
    end
  end
end
