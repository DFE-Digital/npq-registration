class Statement < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider

  validates :cohort_id, presence: true
  validates :lead_provider_id, presence: true

  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :year, numericality: { in: 2020..2030, only_integer: true }
end
