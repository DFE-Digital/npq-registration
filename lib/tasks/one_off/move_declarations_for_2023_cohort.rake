namespace :one_off do
  # for dry run: rake 'one_off:move_declarations_for_2023_cohort[true]'
  # for real run: rake 'one_off:move_declarations_for_2023_cohort[false]'
  desc "Move declarations for 2023 Cohort"
  task :move_declarations_for_2023_cohort, %i[dry_run override_date_checks] => :environment do |_task, args|
    Rails.logger = Logger.new($stdout)
    dry_run = args[:dry_run] != "false"
    override_date_checks = args[:override_date_checks] == "true"

    cohort = Cohort.find_by!(start_year: 2023)

    migration_jan_to_feb = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2025,
        from_month: 1,
        to_year: 2025,
        to_month: 2,
        cohort:,
        from_statement_updates: { output_fee: false },
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    unless migration_jan_to_feb.migrate(dry_run:)
      Rails.logger.info "Validation failure:"
      Rails.logger.info migration_jan_to_feb.errors.full_messages.to_yaml
    end

    migration_jun_to_feb = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2025,
        from_month: 6,
        to_year: 2025,
        to_month: 2,
        cohort:,
        override_date_checks:,
      )

    unless migration_jun_to_feb.migrate(dry_run:)
      Rails.logger.info "Validation failure:"
      Rails.logger.info migration_jun_to_feb.errors.full_messages.to_yaml
    end
  end
end
