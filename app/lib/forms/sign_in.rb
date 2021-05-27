module Forms
  class SignIn < Base
    attr_accessor :email

    validates :email, presence: true, email: true

    def self.permitted_params
      [
        :email,
      ]
    end

    def next_step
      :sign_in_code
    end

    def after_save
      user = User.find_by(email: email)

      if user
        # TODO: extract out
        code = Services::OtpCodeGenerator.new.call
        user.update!(otp_hash: code, otp_expires_at: 15.minutes.from_now)
        ConfirmEmailMailer.confirmation_code_mail(to: email, code: code).deliver_now
      end
    end
  end
end
