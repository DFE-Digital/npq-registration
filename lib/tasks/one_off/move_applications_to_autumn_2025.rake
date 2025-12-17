namespace :one_off do
  desc "Move autumn applications from Spring 2025 Cohort to Autumn 2025"
  task :move_applications_to_autumn_2025, %i[lead_provider_id dry_run] => :versioned_environment do |_task, args|
    Rails.logger = Logger.new($stdout, level: Rails.configuration.log_level) unless Rails.env.test?

    dry_run = args[:dry_run] != "false"
    lead_provider = LeadProvider.find(args[:lead_provider_id])
    limit = 2000

    changelog = Rails.env.test? ? Tempfile : Rails.root.join("tmp/migrated_applications.csv")

    changelog.open("w") do |changelog|
      OneOff::MoveApplicationsToAutumn2025.new(lead_provider:, changelog:, limit:)
                                          .move!(dry_run:)
    end
  end
end
