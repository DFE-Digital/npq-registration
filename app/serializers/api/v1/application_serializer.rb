# frozen_string_literal: true

require "jsonapi/serializer/instrumentation"

module Api
  module V1
    class ApplicationSerializer
      include JSONAPI::Serializer
      include JSONAPI::Serializer::Instrumentation

      attributes :course_identifier,
                 :email,
                 :email_validated,
                 :employer_name,
                 :employment_role,
                 :full_name,
                 :funding_choice,
                 :headteacher_status,
                 # :ineligible_for_funding_reason, # TODO missing
                 :participant_id,
                 :private_childcare_provider_urn,
                 :teacher_reference_number,
                 :teacher_reference_number_validated,
                 :school_urn,
                 :school_ukprn,
                 :status,
                 :works_in_school

      attribute(:participant_id) do |object|
        object.user.ecf_id
      end

      attribute(:private_childcare_provider_urn) do |object|
        object.private_childcare_provider&.urn
      end

      attribute(:teacher_reference_number) do |object|
        object.user.trn
      end

      attribute(:teacher_reference_number_validated) do |object|
        object.user.trn_verified
      end

      attribute(:school_urn) do |object|
        object.school&.urn
      end

      attribute(:school_ukprn) do |object|
        object.school&.ukprn
      end

      attribute(:full_name) do |object|
        object.user.full_name
      end

      attribute(:email) do |object|
        object.user.email
      end

      attribute(:email_validated) do
        true
      end

      attribute(:course_identifier) do |object|
        object.course.identifier
      end

      attribute :created_at do |object|
        object.created_at.rfc3339
      end

      attribute :updated_at do |object|
        [
          object.user.updated_at,
          object.updated_at,
        ].compact.max.rfc3339
      end

      attribute(:status, &:lead_provider_approval_status)

      attribute :cohort do |object|
        # object.cohort.start_year.to_s # TODO can't find a link at the moment
        nil
      end

      attribute(:eligible_for_funding, &:eligible_for_funding)
      attribute(:targeted_delivery_funding_eligibility)

      attribute :teacher_catchment, &:teacher_catchment
      # attribute :teacher_catchment_iso_country_code # TODO missing
      attribute :teacher_catchment_country
      attribute(:itt_provider, &:itt_provider_id)
      attribute :lead_mentor
    end
  end
end
