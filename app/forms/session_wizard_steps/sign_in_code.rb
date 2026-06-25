module SessionWizardSteps
  class SignInCode < Base
    attr_accessor :code

    validates :code, presence: true, length: { is: 8 }
    validate :otp_validation

    def self.permitted_params
      [
        :code,
      ]
    end

    def next_step
      nil
    end

    def admin
      @admin ||= Admin.find_by(email: wizard.store["email"])
    end
    alias_method :user, :admin

  private

    def otp
      return unless OTP.valid_code?(user&.otp_hash) && user.otp_expires_at.present?

      @otp ||= OTP.from(code: user.otp_hash, expires_at: user.otp_expires_at)
    end

    def otp_validation
      return errors.add(:code, :incorrect) unless otp&.matches?(code)

      errors.add(:code, :expired) if otp.expired?
    end
  end
end
