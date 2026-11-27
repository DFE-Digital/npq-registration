module Questionnaires
  class IneligibleForFundingNotInEngland < Base
    def previous_step
      :teacher_catchment
    end

    def next_step
      :choose_your_npq
    end
  end
end
