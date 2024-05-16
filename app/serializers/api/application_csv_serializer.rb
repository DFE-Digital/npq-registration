# frozen_string_literal: true

require "csv"

module API
  class ApplicationCsvSerializer
    attr_reader :scope

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

    def initialize(scope)
      @scope = scope
    end

    def call
      CSV.generate do |csv|
        csv << CSV_HEADERS

        scope.each do |record|
          csv << to_row(record)
        end
      end
    end

  private

    def to_row(record)
      [
        record.ecf_id,
        record.user.ecf_id,
        record.user.full_name,
        record.user.email,
        true,
        record.user.trn,
        record.user.trn_verified,
        record.school&.urn,
        record.school&.ukprn,
        record.private_childcare_provider&.provider_urn,
        record.headteacher_status,
        record.eligible_for_funding,
        record.funding_choice,
        record.course.identifier,
        record.lead_provider_approval_status,
        record.works_in_school,
        record.employer_name,
        record.employment_role,
        record.created_at.rfc3339,
        updated_at(record),
        record.cohort&.start_year&.to_s,
        record.ineligible_for_funding_reason,
        record.targeted_delivery_funding_eligibility,
        teacher_catchment(record),
        record.teacher_catchment_country,
        record.teacher_catchment_iso_country_code,
        record.itt_provider&.legal_name,
        record.lead_mentor,
      ]
    end

    def teacher_catchment(record)
      record.inside_uk_catchment?
    end

    def updated_at(record)
      [
        record.user.updated_at,
        record.updated_at,
      ].compact.max.rfc3339
    end
  end
end
