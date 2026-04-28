module Questionnaires
  class CheckAnswers < Base
    def previous_step
      :share_provider
    end

    def next_step; end

    def last_step?
      true
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
