module Questionnaires
  class RegistrationInterestNotification
    include ActiveModel::Model

    attr_accessor :email

    validate :validate_unique_email
    validates :email, presence: true, length: { maximum: 128 }, email: true

    def validate_unique_email
      return if RegistrationInterest.find_by(email:).blank?

      errors.add(:email, :taken)
    end

    def save!
      RegistrationInterest.create!(email:)
    end
  end
end
