module SessionWizardSteps
  class SignInCode < Base
    attr_accessor :code

    validates :code, presence: true, length: { is: 8 }, user_otp_code: true

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
  end
end
