module Questionnaires
  class PossibleFunding < Base
    include Helpers::Institution

    def next_step
      :choose_your_provider
    end

    def previous_step
      if course.npqlpm?
        if maths_understanding?
          :maths_eligibility_teaching_for_mastery
        else
          :maths_understanding_of_approach
        end
      else
        :choose_your_npq
      end
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

    def is_funding_eligibility_unclear?
      return true if referred_by_return_to_teaching_adviser?
      return true if works_in_another_setting? && employment_type_local_authority_virtual_school?
      return true if works_in_another_setting? && local_authority_supply_teacher?
      return false if works_in_another_setting? &&
        (employment_type_hospital_school? || young_offender_institution?) &&
        (course.ehco? || course.npqh? || course.npqs? || course.npqlpm?)

        works_in_another_setting? && (employment_type_other? || valid_employent_type_for_england?)
    end

    delegate_missing_to :query_store
  end
end
