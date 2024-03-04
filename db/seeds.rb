require "faker"
require "csv"

# Parallel Tests is seeding the database, so I am skipping this in the test environment
return if Rails.env.test?

PaperTrail.enabled = false

Faker::Config.locale = "en-GB"

def load_base_file(file)
  base_file = Rails.root.join("db", "seeds", "base", file)

  load(base_file)
end

Rails.logger.info("Seeding database")

seed_files = [
  "add_cohorts.rb",
  "add_lead_providers.rb",
  "add_itt_providers.rb",
  "add_courses.rb",
  "add_schools.rb",
  "add_childcare_providers.rb",
  "add_statements.rb",
  "add_settings.rb",
].tap do |files|
  if Rails.env.in?(%w[development review])
    files.push(
      "add_users.rb",
      "add_applications.rb",
      "add_api_tokens.rb",
    )
  end
end

seed_files.each do |seed_file|
  Rails.logger.info("seeding #{seed_file}")
  load_base_file(seed_file)
end

PaperTrail.enabled = true
