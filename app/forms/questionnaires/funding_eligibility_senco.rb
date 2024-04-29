module Questionnaires
  class FundingEligibilitySenco < Base
    def previous_step
      if wizard.query_store.senco_in_role_status?
        :senco_start_date
      else
        :senco_in_role
      end
    end

    def next_step
      :choose_your_provider
    end

    def course
      @course ||= wizard.query_store.course
    end

    def funding_eligibility_senco
      "funding_eligibility_senco" if course.npqs?
    end
  end
end
