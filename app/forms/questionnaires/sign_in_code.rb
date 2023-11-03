module Questionnaires
  class SignInCode < Base
    attr_accessor :code

    validates :code, presence: true, length: { is: 6 }
    validate :validate_correct_code

    def self.permitted_params
      [
        :code,
      ]
    end

    def next_step
      nil
    end

    def user
      @user ||= User.find_by(email: wizard.store["email"])
    end

  private

    def validate_correct_code
      if user.blank?
        errors.add(:code, :incorrect)
      elsif code == user.otp_hash
        if user.otp_expires_at < Time.zone.now
          errors.add(:code, :expired)
        end
      else
        errors.add(:code, :incorrect)
      end
    end
  end
end
