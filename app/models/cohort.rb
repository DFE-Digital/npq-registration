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

  def registration_start_date_matches_start_year
    unless registration_start_date && registration_start_date.year == start_year
      errors.add(:registration_start_date, "year must match the start year")
    end
  end

  def self.current(timestamp = Time.zone.today)
    where(registration_start_date: ..timestamp)
      .order(start_year: :desc)
      .first!
  end
end
