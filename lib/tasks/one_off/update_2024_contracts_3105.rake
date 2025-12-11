namespace :one_off do
  desc "One off task for ticket CPDNPQ-3105 to update contracts in 2024 cohort"
  task :update_2024_contracts, %i[file_path dry_run] => :versioned_environment do |_t, args|
    dry_run = args[:dry_run] != "false"

    Rails.logger = Logger.new($stdout) unless Rails.env.test?
    Rails.logger.level = Logger::INFO

    Rails.logger.info "Dry Run" if dry_run

    # 2025 statements
    (7..12).each do |month|
      OneOff::UpdateContracts.call(year: 2025, month: month, cohort_year: 2024, csv_path: args[:file_path], dry_run:)
    end
    # 2026 statements
    (1..12).each do |month|
      OneOff::UpdateContracts.call(year: 2026, month: month, cohort_year: 2024, csv_path: args[:file_path], dry_run:)
    end
    # 2027 statements
    (1..4).each do |month|
      OneOff::UpdateContracts.call(year: 2027, month: month, cohort_year: 2024, csv_path: args[:file_path], dry_run:)
    end
  end
end
