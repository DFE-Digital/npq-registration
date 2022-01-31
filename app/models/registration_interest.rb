class RegistrationInterest < ApplicationRecord
  validates :email,
            presence: true,
            length: { maximum: 128 },
            uniqueness: { case_sensitive: false }
end
