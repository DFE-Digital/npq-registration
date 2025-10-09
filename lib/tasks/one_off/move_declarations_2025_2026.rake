namespace :one_off do
  # for dry run: rake 'one_off:move_declarations_2025_2026[true]'
  # for real run: rake 'one_off:move_declarations_2025_2026[false]'
  desc "Move declarations from Oct25 to Dec25 for 2022 Cohort"
  task :move_declarations_2025_2026, %i[dry_run override_date_checks] => :environment do |_task, args|
    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    dry_run = args[:dry_run] != "false"
    override_date_checks = args[:override_date_checks] == "true"

    migration_1_description = "update output_fee for May 2026 statement in 2021 cohort"
    migration_1 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 5,
        to_year: 2026,
        to_month: 5,
        cohort: Cohort.find_by!(start_year: 2021),
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migration_2_description = "move declarations from Dec 2025 to Jan 2026 in 2022 cohort"
    migration_2 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2025,
        from_month: 12,
        to_year: 2026,
        to_month: 1,
        cohort: Cohort.find_by!(start_year: 2022),
        from_statement_updates: { output_fee: false },
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migration_3_description = "move declarations from Dec 2025 to Jan 2026 in 2023 cohort"
    migration_3 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2025,
        from_month: 12,
        to_year: 2026,
        to_month: 1,
        cohort: Cohort.find_by!(start_year: 2023),
        from_statement_updates: { output_fee: false },
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migration_4_description = "update output_fee for May 2026 statement in 2023 cohort"
    migration_4 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 5,
        to_year: 2026,
        to_month: 5,
        cohort: Cohort.find_by!(start_year: 2023),
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migration_5_description = "update output_fee for Jul 2026 statement in 2023 cohort"
    migration_5 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 7,
        to_year: 2026,
        to_month: 7,
        cohort: Cohort.find_by!(start_year: 2023),
        to_statement_updates: { output_fee: false },
        override_date_checks:,
      )

    migration_6_description = "update output_fee for Sept 2026 statement in 2023 cohort"
    migration_6 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 9,
        to_year: 2026,
        to_month: 9,
        cohort: Cohort.find_by!(start_year: 2023),
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migration_7_description = "update output_fee for Oct 2026 statement in 2023 cohort"
    migration_7 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 10,
        to_year: 2026,
        to_month: 10,
        cohort: Cohort.find_by!(start_year: 2023),
        to_statement_updates: { output_fee: false },
        override_date_checks:,
      )

    migration_8_description = "move declarations from Jan 2026 to Feb 2026 in 2024 cohort"
    migration_8 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 1,
        to_year: 2026,
        to_month: 2,
        cohort: Cohort.find_by!(start_year: 2024),
        from_statement_updates: { output_fee: false },
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migration_9_description = "update output_fee for Mar 2026 statement in 2024 cohort"
    migration_9 = OneOff::MigrateDeclarationsBetweenStatements
      .new(
        from_year: 2026,
        from_month: 3,
        to_year: 2026,
        to_month: 3,
        cohort: Cohort.find_by!(start_year: 2024),
        to_statement_updates: { output_fee: true },
        override_date_checks:,
      )

    migrations = {
      migration_1_description => migration_1,
      migration_2_description => migration_2,
      migration_3_description => migration_3,
      migration_4_description => migration_4,
      migration_5_description => migration_5,
      migration_6_description => migration_6,
      migration_7_description => migration_7,
      migration_8_description => migration_8,
      migration_9_description => migration_9,
    }
    results = {}

    Rails.logger.info "Dry Run" if dry_run

    migrations.each do |description, migration|
      Rails.logger.info "------------------------------------------------------------"
      Rails.logger.info description
      Rails.logger.info "------------------------------------------------------------"
      result = migration.migrate(dry_run:)
      results[description] = result
      unless result
        Rails.logger.info "Errors for '#{description}':"
        Rails.logger.info migrations[description].errors.full_messages.to_yaml
      end
    end

    Rails.logger.info "============================================================"
    Rails.logger.info "Summary:"
    results.each do |description, result|
      Rails.logger.info "Result of '#{description}': #{result}"
    end
  end
end
