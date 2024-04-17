module API
  class ApplicationSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:course_identifier) { |a| a.course.identifier }
      field(:participant_id) { |a| a.user.ecf_id }
      field(:email) { |a| a.user.email }
      field(:full_name) { |a| a.user.full_name }
      field(:teacher_reference_number) { |a| a.user.trn }
      field(:teacher_reference_number_validated) { |a| a.user.trn_verified }
      field(:private_childcare_provider_urn) { |a| a.private_childcare_provider&.provider_urn }
      field(:cohort) { |a| a.cohort&.start_year&.to_s }
      field(:itt_provider) { |a| a.itt_provider&.legal_name }
      field(:employer_name)
      field(:employment_role)
      field(:funding_choice)
      field(:headteacher_status)
      field(:school_urn) { |a| a.school&.urn }
      field(:school_ukprn) { |a| a.school&.ukprn }
      field(:works_in_school)
      field(:email_validated) { true }
      field(:lead_provider_approval_status, name: :status)
      field(:targeted_delivery_funding_eligibility)
      field(:eligible_for_funding)
      field(:teacher_catchment) { |a| a.teacher_catchment.present? }
      field(:teacher_catchment_country)
      field(:teacher_catchment_iso_country_code)
      field(:lead_mentor)
      field(:ineligible_for_funding_reason)
      field(:created_at)
      field(:updated_at) do |a|
        [
          a.user.updated_at,
          a.updated_at,
        ].compact.max
      end

      view :v3 do
        # When we migrate schedules we can implement this fully.
        field(:schedule_identifier) { "placeholder-schedule-identifier" }
      end
    end

    association :attributes, blueprint: AttributesSerializer do |application|
      application
    end

    view :v3 do
      association :attributes, blueprint: AttributesSerializer, view: :v3 do |application|
        application
      end
    end
  end
end
