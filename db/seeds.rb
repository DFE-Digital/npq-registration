require "faker"
require "csv"

return unless Rails.env.in?(%w[development review sandbox])

PaperTrail.enabled = false

Faker::Config.locale = "en-GB"

def load_base_file(file)
  base_file = Rails.root.join("db", "seeds", "base", file)

  load(base_file)
end

def with_versioning
  was_enabled = PaperTrail.enabled?
  was_enabled_for_request = PaperTrail.request.enabled?
  PaperTrail.enabled = true
  PaperTrail.request.enabled = true
  begin
    yield
  ensure
    PaperTrail.enabled = was_enabled
    PaperTrail.request.enabled = was_enabled_for_request
  end
end

Rails.logger.info("Seeding database")

# Due to migrations modifying the tables, we need to reset column informations before running seeds
ApplicationRecord.descendants.each(&:reset_column_information)

# Ensure course/course group are first so the replant for
# review apps doesn't cause the container to go into an
# unhealthy state for too long (as courses are loaded in healthcheck).
[
  "add_course_groups.rb",
  "add_courses.rb",
  "add_feature_flags.rb",
  "add_cohorts.rb",
  "add_childcare_providers.rb",
  "add_schools.rb",
  "add_schedules.rb",
  "add_lead_providers.rb",
  "add_itt_providers.rb",
  "add_users.rb",
  "add_applications.rb",
  "add_statements.rb",
  "add_contracts.rb",
  "add_declarations.rb",
  "add_api_tokens.rb",
  "process_statements.rb",
  "add_delivery_partners.rb",
].each do |seed_file|
  Rails.logger.info("seeding #{seed_file}")
  ApplicationRecord.transaction do
    load_base_file(seed_file)
  end
end
