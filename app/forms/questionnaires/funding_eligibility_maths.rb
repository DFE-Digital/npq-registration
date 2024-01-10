module Questionnaires
  class FundingEligibilityMaths < Base
    def previous_step
      if wizard.query_store.maths_understanding?
        :maths_eligibility_teaching_for_mastery
      else
        :maths_understanding_of_approach
      end
    end

    def next_step
      :choose_your_provider
    end

    def course
      @course ||= wizard.query_store.course
    end

    def funding_eligible_math
      "funding_eligible_maths" if course.npqlpm?
    end
  end
end
