module Questionnaires
  class Start < Base
    def requirements_met?
      true
    end

    def next_step
      if query_store.current_user.present?
        first_questionnaire_step
      else
        # This shouldn't really be reached, in this situation the user should have been
        # presented the omniauth kickoff button on the start back. This is here as a fallback
        # to send the user back to the start page where they'll be presented the oauth button again.
        :start
      end
    end
  end
end
