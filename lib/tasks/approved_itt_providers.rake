# This rake task is run to update the aprroved ITT providers list latest list was provided by Jake Bolger
# Source: https://www.gov.uk/government/publications/accredited-initial-teacher-training-itt-providers/list-of-providers-accredited-to-deliver-itt-from-september-2024

# Run examples:
# bundle exec rake 'approved_itt_providers:update[lib/approved_itt_providers/24-11-2022/approved_itt_providers.csv]'

namespace :approved_itt_providers do
  desc "update the itt providers list"
  task :update, %i[file_name] => :environment do |_t, args|
    file_name = args.file_name

    Rails.logger.info("Importing Approved ITT providers from CSV file: #{file_name}")

    Services::ApprovedIttProviders::Update.call(file_name:)

    Rails.logger.info("Import finished")
  end
end
