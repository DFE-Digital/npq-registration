class LegacyPassedParticipantOutcome < ApplicationRecord
  # Data imported from the decommissioned DQT service
  # https://dfedigital.atlassian.net/browse/CPDNPQ-2116

  # Optional because some legacy short codes might have no course
  belongs_to :course, foreign_key: :course_short_code, primary_key: :short_code, optional: true

  scope :for_display, -> { includes(:course).order(completion_date: :desc, id: :desc) }

  def course_name
    course&.name || course_short_code
  end
end
