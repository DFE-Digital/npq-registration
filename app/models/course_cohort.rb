class CourseCohort < ApplicationRecord
  belongs_to :course
  belongs_to :cohort

  has_many :course_cohort_providers, dependent: :destroy
  has_many :lead_providers, through: :course_cohort_providers

  validates :course_id, uniqueness: { scope: :cohort_id }
end
