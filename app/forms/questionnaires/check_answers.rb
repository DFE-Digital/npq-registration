module Questionnaires
  class CheckAnswers < Base
    def requirements_met?
      wizard.query_store.has_answers?
    end

    def previous_step
      :share_provider
    end

    def next_step
      :continue_to_login unless user_logged_in?
    end

    def last_step?
      user_logged_in?
    end

    def after_save
      return unless user_logged_in?

      wizard.store["email_template"] = email_template

      wizard.store["submitted"] = true
      wizard.session["clear_tra_login"] = true

      HandleSubmissionForStore.new(store: wizard.store).call
    end

    def email_template
      @email_template ||= EmailTemplate.call(data: wizard.store)
    end

  private

    def user_logged_in?
      wizard.current_user
    end
  end
end
