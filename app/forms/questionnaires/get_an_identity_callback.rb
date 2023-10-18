module Questionnaires
  class GetAnIdentityCallback < Base
    def skip_step?
      true
    end

    def next_step
      first_questionnaire_step
    end

    def previous_step
      :start
    end
  end
end
