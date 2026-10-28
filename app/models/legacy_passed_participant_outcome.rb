class LegacyPassedParticipantOutcome < ApplicationRecord
  # Data imported from the decommissioned DQT service
  # https://dfedigital.atlassian.net/browse/CPDNPQ-2116

  def course_name
    Course.find_by(short_code: course_short_code)&.name || course_short_code
  end
end
