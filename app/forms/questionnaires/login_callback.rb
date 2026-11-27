module Questionnaires
  class LoginCallback < Base
    def skip_step?
      true
    end

    def previous_step
      :continue_to_login
    end

    def next_step
      show_previously_funded_alert? ? show_funding_step : :check_answers_and_submit
    end
  end
end
