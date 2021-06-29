module Forms
  class ResendCode < Base
    attr_reader :email

    validates :email, presence: true, email: true, length: { maximum: 128 }

    def self.permitted_params
      %i[
        email
      ]
    end

    def email=(value)
      unless value.nil?
        @email = value.strip.downcase
      end
    end

    def next_step
      :confirm_email
    end

    def previous_step
      :confirm_email
    end

    def after_save
      ConfirmEmailMailer.confirmation_code_mail(to: email, code: code).deliver_now
      wizard.request.flash[:success] = "We've emailed a confirmation code to #{email}"
    end

  private

    def code
      wizard.store["generated_confirmation_code"]
    end
  end
end
