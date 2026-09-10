module Questionnaires
  class ContinueToLogin < Base
    def previous_step
      :check_answers
    end

    def next_step
      :check_answers_and_submit
    end
  end
end
