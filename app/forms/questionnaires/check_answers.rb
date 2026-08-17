module Questionnaires
  class CheckAnswers < Base
    def requirements_met?
      super && wizard.query_store.has_answers?
    end

    def previous_step
      :share_provider
    end

    def next_step
      :continue_to_login
    end
  end
end
