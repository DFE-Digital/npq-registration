class SeedingJob < ApplicationJob
  load(Rails.root.join("db/seeds/base/add_applications.rb"))
  load(Rails.root.join("db/seeds/base/add_declarations.rb"))

  queue_as :default

  def perform
    return unless Rails.env.in?(%w[development review staging sandbox])

    PaperTrail.enabled = false
    Faker::Config.locale = "en-GB"

    ApplicationRecord.transaction do
      SeedAddApplications.new.load(multiplier: 30)
      SeedAddDeclarations.new.load(multiplier: 30)
    end
  end

  def max_attempts
    1
  end
end
