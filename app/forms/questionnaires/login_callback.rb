module Questionnaires
  class LoginCallback < Base
    def skip_step?
      true
    end

    def next_step
      :check_answers
    end

    def previous_step
      :continue_to_login
    end
  end
end
