module Questionnaires
  class DqtMismatch < Base
    def previous_step
      :qualified_teacher_check
    end

    def next_step
      return :check_answers if changing_answer?

      :provider_check
    end
  end
end
