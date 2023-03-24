module Forms
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
      return if skip_sending_otp

      user = User.find_by(email:)

      if user
        # TODO: extract out
        code = Services::OtpCodeGenerator.new.call
        user.update!(otp_hash: code, otp_expires_at: 15.minutes.from_now)
        ConfirmEmailMailer.confirmation_code_mail(to: email, code:).deliver_now
      end
    end

    def skip_sending_otp
      Rails.env.development? && @email == "admin@example.com"
    end
  end
end
