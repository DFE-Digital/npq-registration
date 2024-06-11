# frozen_string_literal: true

require "csv"

module API
  class ApplicationsCsvSerializer
    attr_reader :applications

    CSV_HEADERS = %w[
      id
      participant_id
      full_name
      email
      email_validated
      teacher_reference_number
      teacher_reference_number_validated
      school_urn
      school_ukprn
      private_childcare_provider_urn
      headteacher_status
      eligible_for_funding
      funding_choice
      course_identifier
      status
      works_in_school
      employer_name
      employment_role
      created_at
      updated_at
      cohort
      ineligible_for_funding_reason
      targeted_delivery_funding_eligibility
      teacher_catchment
      teacher_catchment_country
      teacher_catchment_iso_country_code
      itt_provider
      lead_mentor
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
        application.ecf_id,
        application.user.ecf_id,
        application.user.full_name,
        application.user.email,
        true,
        application.user.trn,
        application.user.trn_verified,
        application.school&.urn,
        application.school&.ukprn,
        application.private_childcare_provider&.provider_urn,
        application.headteacher_status,
        application.eligible_for_funding,
        application.funding_choice,
        application.course.identifier,
        application.lead_provider_approval_status,
        application.works_in_school,
        application.employer_name,
        application.employment_role,
        application.created_at.rfc3339,
        updated_at(application),
        application.cohort&.start_year&.to_s,
        application.ineligible_for_funding_reason,
        application.targeted_delivery_funding_eligibility,
        teacher_catchment(application),
        application.teacher_catchment_country,
        application.teacher_catchment_iso_country_code,
        application.itt_provider&.legal_name,
        application.lead_mentor,
      ]
    end

    def teacher_catchment(application)
      application.inside_uk_catchment?
    end

    def updated_at(application)
      [
        application.user.updated_at,
        application.updated_at,
      ].compact.max.rfc3339
    end
  end
end
