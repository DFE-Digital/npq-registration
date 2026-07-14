module Questionnaires
  class IneligibleForFundingPreviouslyFunded < Base
    def previous_step
      :funding_history
    end

    def next_step
      :work_setting
    end
  end
end
