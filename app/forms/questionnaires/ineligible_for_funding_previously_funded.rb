module Questionnaires
  class IneligibleForFundingPreviouslyFunded < Base
    def previous_step
      :funding_history
    end

    def next_step
      funding_your_npq_step
    end
  end
end
