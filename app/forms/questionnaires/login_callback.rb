module Questionnaires
  class LoginCallback < Base
    def skip_step?
      true
    end

    def previous_step
      :continue_to_login
    end

    def next_step
      if show_previously_funded_alert?
        if query_store.course.ehco?
          :funding_your_ehco
        else
          :funding_your_npq
        end
      else
        :check_answers_and_submit
      end
    end
  end
end
