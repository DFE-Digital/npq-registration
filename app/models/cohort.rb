class Cohort < ApplicationRecord
  validates :start_year,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 2021,
              less_than: 2030,
            },
            uniqueness: true

  def self.current
    where(registration_start_date: ..Time.zone.today)
      .order(start_year: :desc)
      .first!
  end
end
