module Questionnaires
  class IneligibleForFundingPreviouslyFunded < Base
    def previous_step
      :funding_history
    end

    def next_step
      if query_store.course.ehco?
        :funding_your_ehco
      else
        :funding_your_npq
      end
    end
  end
end
