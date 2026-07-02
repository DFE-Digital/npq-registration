module SessionWizardSteps
  class SignInCode < Base
    attr_accessor :code

    validates :code, presence: true, length: { is: 8 }, user_otp_code: true

    after_validation :register_otp_attempt

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

    def register_otp_attempt
      admin&.register_otp_attempt!(success: errors.none?) if code.present?
    end
  end
end
