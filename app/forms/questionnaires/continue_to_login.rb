module Questionnaires
  class ContinueToLogin < Base
    def previous_step
      :check_answers
    end

    def next_step
      :check_answers
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
  end
end
