namespace :one_off do
  desc "One off task for ticket 2350 to update contracts"
  task :create_or_update_statements, %i[file_path] => :environment do |_t, args|
    OneOff::CreateOrUpdateStatements.new.call(cohort_year: 2021, csv_path: args[:file_path])
  end
end
