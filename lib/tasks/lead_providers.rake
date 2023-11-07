namespace :lead_providers do
  desc "Updates Lead Providers in DB to match LeadProvider::ALL_PROVIDERS"
  task update: :environment do |t|
    Rails.logger.info("Running #{t.name}")

    LeadProviders::Updater.call

    Rails.logger.info("#{t.name} finished")
  end
end
