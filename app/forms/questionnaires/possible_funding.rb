module Questionnaires
  class PossibleFunding < Base
    include Helpers::Institution

    def next_step
      :choose_your_provider
    end

    def previous_step
      if course.npqlpm?
        if wizard.query_store.maths_understanding?
          :maths_eligibility_teaching_for_mastery
        else
          :maths_understanding_of_approach
        end
      else
        :choose_your_npq
      end
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
      return "lead_mentor" if course.npqltd? && !is_funding_eligibility_unclear?
      return "funding_eligibility_unclear" if is_funding_eligibility_unclear?

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

    def valid_employent_type_for_england?
      wizard.query_store.valid_employent_type_for_england?
    end

    def is_funding_eligibility_unclear?
      works_in_other? && (employment_type_other? || valid_employent_type_for_england?)
    end

    def targeted_delivery_funding_eligibility?
      wizard.query_store.targeted_delivery_funding_eligibility?
    end

    def tsf_primary_plus_eligibility?
      wizard.query_store.tsf_primary_plus_eligibility?
    end
  end
end
