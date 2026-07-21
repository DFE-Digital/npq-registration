module Questionnaires
  class Start < Base
    def requirements_met?
      true
    end

    def next_step
      first_questionnaire_step
    end
  end
end
