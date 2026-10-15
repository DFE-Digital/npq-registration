module Questionnaires
  class ContinueToLogin < Base
    def previous_step
      :check_answers
    end

    def next_step
      # next_step not used here - the login callback handles this
    end
  end
end
