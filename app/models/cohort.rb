class Cohort < ApplicationRecord
  validates :start_year,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 2021,
              less_than: 2030,
            },
            uniqueness: true

  validates :registration_start_date, presence: true
  validate :registration_start_date_matches_start_year
  validates :funding_cap,
            inclusion: {
              in: [true, false],
              message: "Choose true or false for funding cap",
            }

  def registration_start_date_matches_start_year
    return if registration_start_date.blank?

    errors.add(:registration_start_date, "year must match the start year") if registration_start_date.year != start_year
  end

  def self.current(timestamp = Time.zone.today)
    where(registration_start_date: ..timestamp)
      .order(start_year: :desc)
      .first!
  end

  def self.active_registration_cohort
    where(registration_start_date: ..Date.current).order(start_year: :desc).first.presence || current
  end
end
