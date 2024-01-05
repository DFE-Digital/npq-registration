class Schedule < ApplicationRecord
  belongs_to :course_group
  belongs_to :cohort
  has_many :applications

  validates :name, presence: true
  validates :declaration_starts_on, presence: true
  validates :schedule_applies_from, presence: true
  validates :schedule_applies_to, presence: true
  validates :declaration_types, presence: true
end