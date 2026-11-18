class RegistrationInterest < ApplicationRecord
  validates :email,
            presence: true,
            length: { maximum: 128 },
            notify_email: true

  enum :course, {
    "npq-senco": "npq-senco",
    other: "other",
  }, validate: true

  scope :not_yet_notified, -> { where(notified: false) }
  scope :random_sample, ->(count) { order("RANDOM()").first(count) }

  def course_options
    self.class.courses.keys.map do |course|
      OpenStruct.new(value: course, label: I18n.t("registration_interest.courses.#{course}"))
    end
  end

  # We did not originally valid email format so we need to check this before sending
  def valid_email?
    NotifyEmailValidator.valid?(value)
  end
end
