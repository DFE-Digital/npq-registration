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

    def before_render
      wizard.store["pre_login_funding_eligiblity_status_code"] = wizard.query_store.funding_eligiblity_status_code
    end
  end
end
