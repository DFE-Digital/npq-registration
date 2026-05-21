class LeadProvider < ApplicationRecord
  ALL_ACTIVE_PROVIDERS = {
    "Ambition Institute" => "9e35e998-c63b-4136-89c4-e9e18ddde0ea",
    "Best Practice Network" => "57ba9e86-559f-4ff4-a6d2-4610c7259b67",
    "Church of England" => "79cb41ca-cb6d-405c-b52c-b6f7c752388d",
    "LLSE" => "230e67c0-071a-4a48-9673-9d043d456281",
    "National Institute of Teaching" => "3ec607f2-7a3a-421f-9f1a-9aca8a634aeb",
    "School-Led Network" => "bc5e4e37-1d64-4149-a06b-ad10d3c55fd0",
    "Teach First" => "a02ae582-f939-462f-90bc-cebf20fa8473",
    "UCL Institute of Education" => "ef687b3d-c1c0-4566-a295-16d6fa5d0fa7",
  }.freeze

  has_many :applications
  has_many :statements

  has_many :delivery_partnerships
  has_many :delivery_partners, through: :delivery_partnerships

  has_many :course_cohort_providers, dependent: :destroy
  has_many :course_cohorts, through: :course_cohort_providers
  has_many :courses, through: :course_cohorts

  validates :name, presence: true
  validates :ecf_id, uniqueness: { case_sensitive: false }, allow_nil: true

  scope :alphabetical, -> { order(name: :asc) }

  def self.for(course:, cohort: Cohort.current)
    course_cohort = CourseCohort.find_by(course:, cohort:)
    return none unless course_cohort

    LeadProvider.joins(:course_cohort_providers).where(course_cohort_providers: { course_cohort_id: course_cohort.id }).distinct
  end

  def next_output_fee_statement(cohort)
    statements.next_output_fee_statements.where(cohort:).first
  end

  def delivery_partners_for_cohort(cohort)
    delivery_partners.where(delivery_partnerships: { cohort: })
  end
end
