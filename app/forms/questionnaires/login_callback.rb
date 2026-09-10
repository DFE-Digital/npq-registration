module Questionnaires
  class LoginCallback < Base
    def skip_step?
      true
    end

    def previous_step
      :continue_to_login
    end

    def next_step
      :check_answers_and_submit
    end
  end
end
