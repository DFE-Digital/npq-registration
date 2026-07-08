class SeedingJob < ApplicationJob
  load(Rails.root.join("db/seeds/base/add_applications.rb"))
  load(Rails.root.join("db/seeds/base/add_declarations.rb"))

  queue_as :default

  def perform(times: 1)
    return unless Rails.env.in?(%w[development review staging sandbox])
    return unless times.positive?

    PaperTrail.enabled = false
    Faker::Config.locale = "en-GB"

    ApplicationRecord.transaction do
      SeedAddApplications.new.load(multiplier: 20)
      SeedAddDeclarations.new.load(multiplier: 20)
    end

    SeedingJob.perform_later(times: times - 1) if times > 1
  end

  def max_attempts
    1
  end
end
