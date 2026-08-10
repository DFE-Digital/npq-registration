module Questionnaires
  class CheckAnswers < Base
    def requirements_met?
      super && query_store.has_answers?
    end

    def previous_step
      :share_provider
    end

    def next_step
      :continue_to_login
    end

    def answers
      @answers ||= Registration::CheckAnswersPresenter.new(wizard)
    end

    def before_render
      wizard.store["pre_login_funding_eligiblity_status_code"] = query_store.funding_eligiblity_status_code
    end

    def change_path(step_id)
      if Rails.configuration.x.dfe_wizard
        wizard.resolve_step_path(step_id, return_to_review: step_id)
      else
        "/registration/#{step_id.to_s.dasherize}/change"
      end
    end
  end
end
