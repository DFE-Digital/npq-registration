# frozen_string_literal: true

require "csv"

module API
  class EnrolmentsCsvSerializer
    attr_reader :applications

    CSV_HEADERS = %w[
      participant_id
      course_identifier
      schedule_identifier
      cohort
      npq_application_id
      eligible_for_funding
      training_status
      school_urn
      funded_place
    ].freeze

    def initialize(applications)
      @applications = applications
    end

    def serialize
      CSV.generate do |csv|
        csv << CSV_HEADERS

        applications.each do |application|
          csv << to_row(application)
        end
      end
    end

  private

    def to_row(application)
      [
        application.user.ecf_id,
        application.course.identifier,
        application.schedule&.identifier,
        application.cohort.start_year.to_s,
        application.ecf_id,
        application.eligible_for_funding,
        application.training_status,
        application.school.urn,
        application.funded_place,
      ]
    end
  end
end
