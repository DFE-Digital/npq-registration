module Questionnaires
  class PossibleFunding < Base
    def previous_step
      :work_setting
    end

    def next_step
      :choose_your_provider
    end

    def message_template
      return "private_childcare_provider" if query_store.institution.is_a?(PrivateChildcareProvider)
      return "lead_mentor" if course.npqltd? && !is_funding_eligibility_unclear?

      if is_funding_eligibility_unclear?
        "funding_eligibility_unclear"
      elsif query_store.course.npqlpm?
        "funding_eligibility_maths"
      elsif query_store.course.ehco?
        "ehco_possible_funding"
      else
        "eligible_for_scholarship_funding_not_tsf"
      end
    end

  private

    # TODO: test these scenarios
    def is_funding_eligibility_unclear?
      return false if course.ehco?
      return true if referred_by_return_to_teaching_adviser?
      return true if works_in_another_setting? && employment_type_local_authority_virtual_school?
      return true if works_in_another_setting? && local_authority_supply_teacher?

      works_in_another_setting? && (employment_type_other? || valid_employent_type_for_england?)
    end

    delegate_missing_to :query_store
  end
end
