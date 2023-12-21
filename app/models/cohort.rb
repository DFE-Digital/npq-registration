# Cohort
#
# * represents an academic year marker by the start_year
# * also holds the NPQ registration start date which can vary by year
class Cohort < ApplicationRecord
  validates :start_year,
    presence: true,
    numericality: {
      greater_than_or_equal_to: 2021,
      less_than: 2030,
    },
    uniqueness: true
end
