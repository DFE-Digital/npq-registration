namespace :course_cohort_providers do
  desc "Populate course cohort providers"
  task :load, %i[cohort_identifier course_to_provider_csv dry_run] => :versioned_environment do |_t, args|
    dry_run = args[:dry_run] != "false"

    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    logger.info "Dry Run" if dry_run

    raise "Missing required argument: cohort_identifier" unless args.cohort_identifier

    cohort = Cohort.find_by(identifier: args.cohort_identifier)
    raise "Cohort not found with identifier: #{args.cohort_identifier}" unless cohort
    raise "Missing required argument: course_to_provider_csv" unless args.course_to_provider_csv

    CourseCohort.transaction do
      CSV.foreach(args[:course_to_provider_csv], headers: true, header_converters: :symbol, strip: true) do |row|
        course = Course.find_by!(identifier: row[:course_identifier])
        course_cohort = CourseCohort.find_or_create_by!(course:, cohort:)
        lead_provider = LeadProvider.find_by!(name: row[:lead_provider_name])
        course_cohort.course_cohort_providers.find_or_create_by!(lead_provider:)
      end

      if dry_run
        logger.info "Dry run: rolling back"
        raise ActiveRecord::Rollback
      end
    end
  end
end
