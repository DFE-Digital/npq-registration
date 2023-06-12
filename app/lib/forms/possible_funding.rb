module Forms
  class PossibleFunding < Base
    include Helpers::Institution

    def next_step
      :choose_your_provider
    end

    def previous_step
      :choose_your_npq
    end

    def course
      @course ||= wizard.query_store.course
    end

    def funding_amount
      @funding_amount ||= targeted_delivery_funding_eligibility? && tsf_primary_plus_eligibility? ? 800 : 200
    end

    def after_save
      wizard.store["funding_amount"] = funding_amount
    end

    def message_template
      return "private_childcare_provider" if institution.is_a?(PrivateChildcareProvider)
      return "lead_mentor" if Course.npqltd.include?(course)
      return "funding_eligibility_unclear" if works_in_other? && employment_type_other?

      if targeted_delivery_funding_eligibility?
        "eligible_for_scholarship_funding"
      else
        "eligible_for_scholarship_funding_not_tsf"
      end
    end

  private

    def works_in_other?
      wizard.query_store.works_in_other?
    end

    def employment_type_other?
      wizard.query_store.employment_type_other?
    end

    def targeted_delivery_funding_eligibility?
      wizard.query_store.targeted_delivery_funding_eligibility?
    end

    def tsf_primary_plus_eligibility?
      wizard.query_store.tsf_primary_plus_eligibility?
    end
  end
end
