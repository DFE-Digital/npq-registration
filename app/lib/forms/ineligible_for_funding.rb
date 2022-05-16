module Forms
  class IneligibleForFunding < Base
    include Helpers::Institution

    attr_accessor :version

    def self.permitted_params
      [:version]
    end

    def next_step
      :funding_your_npq
    end

    def previous_step
      :choose_your_npq
    end

    def ineligible_template
      @ineligible_template ||= begin
        return version if version.present?

        case funding_eligiblity_status_code
        when Services::FundingEligibility::SCHOOL_OUTSIDE_ENGLAND_OR_CROWN_DEPENDENCIES, Services::FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE
          return 'school/outside_catchment_or_ineligible_establishment'
        when Services::FundingEligibility::PREVIOUSLY_FUNDED
          return 'school/has_already_been_funded'
        when Services::FundingEligibility::EARLY_YEARS_OUTSIDE_ENGLAND_OR_CROWN_DEPENDENCIES, Services::FundingEligibility::NOT_ON_EARLY_YEARS_REGISTER
          return 'early_years/outside_catchment_or_not_on_early_years_register'
        when Services::FundingEligibility::EARLY_YEARS_INVALID_NPQ
          return 'early_years/not_applying_for_NPQEY'
        when Services::FundingEligibility::NO_INSTITUTION
          if query_store.works_in_school?
            return 'school/outside_catchment_or_ineligible_establishment'
          else
            return 'early_years/outside_catchment_or_not_on_early_years_register'
          end
        end
      end

      raise RuntimeError, "Missing status code handling: #{funding_eligiblity_status_code}"
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= Services::FundingEligibility.new(
        course: course,
        institution: institution,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
      ).funding_eligiblity_status_code
    end

    delegate :course, :new_headteacher?, :inside_catchment?, to: :query_store
  end
end
