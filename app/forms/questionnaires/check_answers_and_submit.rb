module Questionnaires
  class CheckAnswersAndSubmit < Base
    def requirements_met?
      super && wizard.query_store.has_answers?
    end

    def previous_step
      :share_provider
    end

    def next_step
      # This is the last step, so there is no next step.
    end

    def last_step?
      true
    end

    def answers
      @answers ||= Registration::CheckAnswersPresenter.new(wizard)
    end

    def show_previously_funded_alert?
      wizard.store["pre_login_funding_eligiblity_status_code"] == :funded && user_previously_funded?
    end

    def before_render
      wizard.store["previously_funded"] = true if user_previously_funded?
      wizard.store["funding_eligiblity_status_code"] = funding_eligibility_calculator.funding_eligiblity_status_code
    end

    def after_save
      wizard.store["email_template"] = email_template

      wizard.store["submitted"] = true
      wizard.session["clear_tra_login"] = true

      HandleSubmissionForStore.new(store: wizard.store).call
    end

    def email_template
      @email_template ||= EmailTemplate.call(data: wizard.store)
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
