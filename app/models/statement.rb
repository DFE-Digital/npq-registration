class Statement < ApplicationRecord
  belongs_to :cohort
  belongs_to :lead_provider

  validates :cohort_id, presence: true
  validates :lead_provider_id, presence: true

  validates :month, numericality: { in: 1..12, only_integer: true }
  validates :year, numericality: { in: 2020..2030, only_integer: true }

  # "deadline_date" the deadline for the final declaration, if this is missed
  # the declaration will be added to the next statement output instead

  # do we need a flag to differentiate between service statements and output
  # statements? Currently they're set by contract managers, translated to CSV
  # by Shahad and implemented by devs. We need to move this to the admin UI
end
