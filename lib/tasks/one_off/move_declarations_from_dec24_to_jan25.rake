namespace :one_off do
  desc "Move declarations from Dec24 to Jan25 for 2021 Cohort"
  task :move_declarations_from_dec24_to_jan25, %i[dry_run override_date_checks] => :environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    dry_run = args[:dry_run] != "false"
    override_date_checks = args[:override_date_checks] == "true"

    cohort = Cohort.find_by!(start_year: 2021)

    migrator = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2024,
        from_month: 12,
        to_year: 2025,
        to_month: 1,
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
