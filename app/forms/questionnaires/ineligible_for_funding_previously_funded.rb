module Questionnaires
  class IneligibleForFundingPreviouslyFunded < Base
    def previous_step
      :funding_history
    end

    def next_step
      show_appropriate_course_step
    end
  end
end
