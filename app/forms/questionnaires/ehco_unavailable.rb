module Questionnaires
  class EhcoUnavailable < Base
    def previous_step
      :npqh_status
    end

    def next_step
      :choose_your_npq
    end
  end
end
