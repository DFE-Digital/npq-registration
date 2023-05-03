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

    def tsf_funding_amount
      @tsf_funding_amount ||= if targeted_delivery_funding_eligibility?
                                tsf_primary_plus_eligibility? ? 800 : 200
                              end
    end

    def after_save
      wizard.store["email_template"] = email_template[message_template]
      wizard.store["tsf_funding_amount"] = tsf_funding_amount
    end

    def message_template
      return "private_childcare_provider" if institution.is_a?(PrivateChildcareProvider)
      return "lead_mentor" if Course.npqltd.include?(course)

      if targeted_delivery_funding_eligibility?
        "eligible_for_scholarship_funding"
      else
        "eligible_for_scholarship_funding_not_tsf"
      end
    end

  private

    def email_template
      {
        "eligible_for_scholarship_funding" => :eligible_scholarship_funding,
        "eligible_for_scholarship_funding_not_tsf" => :eligible_scholarship_funding_not_tsf,
      }
    end

    def targeted_delivery_funding_eligibility?
      wizard.query_store.targeted_delivery_funding_eligibility?
    end

    def tsf_primary_plus_eligibility?
      wizard.query_store.tsf_primary_plus_eligibility?
    end
  end
end
