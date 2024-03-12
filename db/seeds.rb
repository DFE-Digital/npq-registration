require "faker"
require "csv"

return unless Rails.env.in?(%w[development review])

PaperTrail.enabled = false

Faker::Config.locale = "en-GB"

def load_base_file(file)
  base_file = Rails.root.join("db", "seeds", "base", file)

  load(base_file)
end

Rails.logger.info("Seeding database")

[
  "add_childcare_providers.rb",
  "add_schools.rb",
  "add_courses.rb",
  "add_lead_providers.rb",
  "add_itt_providers.rb",
  "add_users.rb",
  "add_applications.rb",
  "add_settings.rb",
  "add_cohorts.rb",
  "add_statements.rb",
  "add_api_tokens.rb",
].each do |seed_file|
  Rails.logger.info("seeding #{seed_file}")
  load_base_file(seed_file)
end

PaperTrail.enabled = true
