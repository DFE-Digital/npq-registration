require "faker"
require "csv"

return unless Rails.env.in?(%w[development review staging sandbox])

PaperTrail.enabled = false

Faker::Config.locale = "en-GB"

def load_base_file(file)
  base_file = Rails.root.join("db/seeds/base", file)

  load(base_file)
end

def load_csv(file, model_class)
  CSV.read(Rails.root.join(file), headers: true).tap do |data|
    import_count = 0
    batch_size = 10_000
    batch = []

    data.each do |row|
      batch << row.to_h
      next unless batch.length >= batch_size

      Rails.logger.info("Importing #{import_count += batch_size} #{model_class.to_s.pluralize}")
      model_class.insert_all(batch)
      batch = []
    end

    unless batch.empty?
      Rails.logger.info("Importing #{import_count + batch.length} #{model_class.to_s.pluralize}")
      model_class.insert_all(batch)
    end
  end
end

Rails.logger.info("Seeding database")

# Due to migrations modifying the tables, we need to reset column informations before running seeds
ApplicationRecord.descendants.each(&:reset_column_information)

# Ensure course/course group are first so the replant for
# review apps doesn't cause the container to go into an
# unhealthy state for too long (as courses are loaded in healthcheck).
{
  "add_course_groups.rb" => nil,
  "add_courses.rb" => nil,
  "add_feature_flags.rb" => nil,
  "add_cohorts.rb" => nil,
  "add_childcare_providers.rb" => nil,
  "add_schools.rb" => nil,
  "add_schedules.rb" => nil,
  "add_lead_providers.rb" => nil,
  "add_itt_providers.rb" => nil,
  "add_users.rb" => nil,
  "add_applications.rb" => "SeedAddApplications",
  "add_statements.rb" => nil,
  "add_contracts.rb" => nil,
  "add_declarations.rb" => "SeedAddDeclarations",
  "add_api_tokens.rb" => nil,
  "process_statements.rb" => nil,
  "add_delivery_partners.rb" => nil,
  "add_eligibility_list_entries.rb" => nil,
  "add_course_cohort_providers.rb" => nil,
}.each do |seed_file, seed_class|
  Rails.logger.info("seeding #{seed_file}")
  ApplicationRecord.transaction do
    load_base_file(seed_file)
    seed_class.constantize.new.load if seed_class
  end
end
