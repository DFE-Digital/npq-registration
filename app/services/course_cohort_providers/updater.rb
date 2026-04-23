module CourseCohortProviders
  class Updater
    def initialize(cohort:, course_to_provider_csv:, dry_run:, logger: Rails.logger)
      @cohort = cohort
      @course_to_provider_csv = course_to_provider_csv
      @dry_run = dry_run
      @logger = logger
    end

    attr_reader :cohort, :course_to_provider_csv, :dry_run, :logger

    def call
      CourseCohort.transaction do
        logger.info "Dry Run" if dry_run

        CSV.foreach(course_to_provider_csv, headers: true, header_converters: :symbol, strip: true) do |row|
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
end
