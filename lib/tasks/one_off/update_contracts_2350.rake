namespace :one_off do
  desc "One off task for ticket 2350 to update contracts"
  task :update_contracts, %i[file_path] => :versioned_environment do |_t, args|
    OneOff::UpdateContracts.call(year: 2024, month: 12, cohort_year: 2024, csv_path: args[:file_path])
  end
end
