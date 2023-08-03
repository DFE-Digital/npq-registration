module Forms
  class FundingEligibilityMaths < Base
    def previous_step
      :choose_your_npq
    end

    def next_step
      :choose_your_provider
    end

    def course
      @course ||= wizard.query_store.course
    end

    def funding_eligible_math
      return "funding_eligible_maths" if Course.npqlpm.include?(course)
    end
  end
end
