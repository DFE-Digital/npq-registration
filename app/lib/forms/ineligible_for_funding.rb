module Forms
  class IneligibleForFunding < Base
    include Helpers::Institution

    SCHOOL_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT = "school/outside_catchment_or_ineligible_establishment".freeze
    SCHOOL_ALREADY_FUNDED = "school/has_already_been_funded".freeze
    EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT = "early_years/outside_catchment_or_not_on_early_years_register".freeze
    EARLY_YEARS_NOT_APPLYING_FOR_NPQEY = "early_years/not_applying_for_NPQEY".freeze

    attr_accessor :version

    def next_step
      :funding_your_npq
    end

    def previous_step
      :choose_your_npq
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when Services::FundingEligibility::SCHOOL_OUTSIDE_CATCHMENT, Services::FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE
                                 return SCHOOL_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                               when Services::FundingEligibility::PREVIOUSLY_FUNDED
                                 return SCHOOL_ALREADY_FUNDED
                               when Services::FundingEligibility::EARLY_YEARS_OUTSIDE_CATCHMENT, Services::FundingEligibility::NOT_ON_EARLY_YEARS_REGISTER
                                 return EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                               when Services::FundingEligibility::EARLY_YEARS_INVALID_NPQ
                                 return EARLY_YEARS_NOT_APPLYING_FOR_NPQEY
                               when Services::FundingEligibility::NO_INSTITUTION
                                 if query_store.works_in_school?
                                   return SCHOOL_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                                 else
                                   return EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                                 end
                               end

      raise "Missing status code handling: #{funding_eligiblity_status_code}"
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= Services::FundingEligibility.new(
        course: course,
        institution: institution,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.store["trn"],
      ).funding_eligiblity_status_code
    end

    delegate :course, :new_headteacher?, :inside_catchment?, to: :query_store
  end
end
