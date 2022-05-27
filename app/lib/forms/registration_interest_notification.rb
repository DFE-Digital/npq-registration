module Forms
  class RegistrationInterestNotification
    include ActiveModel::Model

    attr_accessor :email

    validates :email, presence: true, length: { maximum: 128 }
    validate :validate_unique_email

    def validate_unique_email
      return if RegistrationInterest.find_by(email: email).blank?

      errors.add(:email, :taken)
    end

    def save!
      RegistrationInterest.create!(email: email)
    end
  end
end
