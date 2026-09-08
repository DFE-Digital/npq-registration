class SeedingJob < ApplicationJob
  load(Rails.root.join("db/seeds/base/add_applications.rb"))
  load(Rails.root.join("db/seeds/base/add_declarations.rb"))
  load(Rails.root.join("db/seeds/base/add_users.rb"))

  queue_as :default

  def perform(times: 1, multiplier: 20)
    return unless Rails.env.in?(%w[development review staging sandbox])
    return unless times.positive?

    papertrail_was = PaperTrail.enabled?
    PaperTrail.enabled = false

    Faker::Config.locale = "en-GB"

    ApplicationRecord.transaction do
      SeedAddApplications.new.load(multiplier:)
      SeedAddDeclarations.new.load(multiplier:)
      SeedAddUsers.new.load if times == 1
    end

    PaperTrail.enabled = papertrail_was

    SeedingJob.perform_later(times: times - 1) if times > 1
  end

  def max_attempts
    1
  end
end
