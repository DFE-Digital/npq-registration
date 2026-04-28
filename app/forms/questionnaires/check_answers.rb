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
  end
end
