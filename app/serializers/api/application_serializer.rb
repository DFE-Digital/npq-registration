module API
  class ApplicationSerializer < Blueprinter::Base
    identifier :ecf_id, name: :id
    field(:type) { "npq_application" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:course_identifier) { |a| a.course.identifier }
      field(:email) { |a| a.user.email }
      field(:email_validated) { true }
      field(:employer_name)
      field(:employment_role)
      field(:full_name) { |a| a.user.full_name }
      field(:funding_choice)
      field(:headteacher_status)
      field(:ineligible_for_funding_reason)
      field(:participant_id) { |a| a.user.ecf_id }
      field(:private_childcare_provider_urn) { |a| a.private_childcare_provider&.provider_urn }
      field(:teacher_reference_number) { |a| a.user.trn }
      field(:teacher_reference_number_validated) { |a| a.user.trn_verified }
      field(:school_urn) { |a| a.school&.urn }
      field(:school_ukprn) { |a| a.school&.ukprn }
      field(:lead_provider_approval_status, name: :status)
      field(:works_in_school)
      field(:cohort) { |a| a.cohort&.start_year&.to_s }
      field(:eligible_for_dfe_funding?, name: :eligible_for_funding)
      field(:targeted_delivery_funding_eligibility)
      field(:inside_uk_catchment?, name: :teacher_catchment)
      field(:teacher_catchment_country)
      field(:teacher_catchment_iso_country_code)
      field(:itt_provider) { |a| a.itt_provider&.legal_name }
      field(:lead_mentor)
      field(:funded_place)
      field(:created_at) do |a|
        [
          a.accepted_at,
          a.created_at,
        ].compact.max
      end
      field(:updated_at) do |a|
        [
          a.user.updated_at,
          a.updated_at,
        ].compact.max
      end

      view :v3 do
        field(:schedule_identifier) { |a| a.schedule&.identifier }
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
