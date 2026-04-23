namespace :course_cohort_providers do
  desc "Populate course cohort providers"
  task :load, %i[cohort_identifier course_to_provider_csv dry_run] => :versioned_environment do |_t, args|
    dry_run = args[:dry_run] != "false"

    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    raise "Missing required argument: cohort_identifier" unless args.cohort_identifier

    cohort = Cohort.find_by(identifier: args.cohort_identifier)
    raise "Cohort not found with identifier: #{args.cohort_identifier}" unless cohort
    raise "Missing required argument: course_to_provider_csv" unless args.course_to_provider_csv

    CourseCohortProviders::Updater.new(cohort:, course_to_provider_csv: args.course_to_provider_csv, dry_run:, logger:).call
  end
end
