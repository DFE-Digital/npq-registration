module Forms
  class ResendCode < Base
    def next_step
      :confirm_email
    end

    def after_save
      ConfirmEmailMailer.confirmation_code_mail(to: email, code: code).deliver_now
      wizard.request.flash[:info] = "Another email with confirmation details has been sent to #{email}"
    end

  private

    def email
      wizard.store["email"]
    end

    def code
      wizard.store["generated_confirmation_code"]
    end
  end
end
