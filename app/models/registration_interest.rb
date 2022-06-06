class RegistrationInterest < ApplicationRecord
  validates :email,
            presence: true,
            length: { maximum: 128 },
            uniqueness: { case_sensitive: false }

  scope :not_yet_notified, -> { where(notified: false) }
  scope :random_sample, ->(count) { order("RANDOM()").first(count) }
end
