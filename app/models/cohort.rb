class Cohort < ApplicationRecord
  validates :start_year,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 2021,
              less_than: 2030,
            }
end
