class Schedule < ApplicationRecord
  DECLARATION_TYPES = %w[started retained-1 retained-2 completed].freeze

  belongs_to :course_group
  belongs_to :cohort

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: { scope: :cohort_id }

  validates :applies_from, presence: true
  validates :applies_to, presence: true
end
