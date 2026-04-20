class CourseCohortProvider < ApplicationRecord
  belongs_to :course_cohort
  belongs_to :lead_provider

  validates :course_cohort_id, uniqueness: { scope: :lead_provider_id }
end
