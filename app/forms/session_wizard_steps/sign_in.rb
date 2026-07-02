module SessionWizardSteps
  class SignIn < Base
    attr_reader :email

    validates :email, presence: true, email: true

    def self.permitted_params
      [
        :email,
      ]
    end

    def email=(value)
      if value
        @email = value.strip.downcase
      end
    end

    def next_step
      :sign_in_code
    end

    def after_save
      admin = Admin.find_by(email:)

      if admin
        otp = admin.start_otp!
        ConfirmEmailMailer.confirmation_code_mail(to: email, code: otp.code).deliver_now
      end
    end
  end
end
