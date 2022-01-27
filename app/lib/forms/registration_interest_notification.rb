module Forms
  class RegistrationInterestNotification
    include ActiveModel::Model

    VALID_NOTIFICATION_OPTIONS = %w[yes no].freeze

    attr_accessor :email, :notification_option, :term_interest_registered

    validates :notification_option, inclusion: { in: VALID_NOTIFICATION_OPTIONS }
    validates :email,
              presence: true,
              length: { maximum: 128 },
              unless: :selected_no?
    validate :can_register_interest

    def term
      term_interest_registered || "Autumn 2022"
    end

    def selected_no?
      notification_option == "no"
    end

    def can_register_interest
      if RegistrationInterest.find_by(email: email).present?
        errors.add(:email, :taken)
      end
    end

    def save!
      RegistrationInterest.create!(email: email, term: term)
    end
  end
end
