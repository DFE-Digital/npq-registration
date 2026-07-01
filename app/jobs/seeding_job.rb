class SeedingJob < ApplicationJob
  queue_as :default

  def perform
    return unless Rails.env.in?(%w[development review staging sandbox])
    return unless Rails.configuration.x.large_scale_seeding

    PaperTrail.enabled = false
    Faker::Config.locale = "en-GB"

    load(Rails.root.join("db/seeds/base/add_applications.rb"))
    load(Rails.root.join("db/seeds/base/add_declarations.rb"))
  end
end
