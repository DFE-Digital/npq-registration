class Schedule < ApplicationRecord
  DECLARATION_TYPES = %w[started retained-1 retained-2 completed].freeze

  belongs_to :course_group
  belongs_to :cohort

  validates :name, presence: true
  validates :identifier, presence: true, uniqueness: { scope: :cohort_id }

  validates :applies_from, presence: true
  validates :applies_to, presence: true

  def self.default_for(course_group:, cohort: Cohort.current)
    case course_group.name
    when "specialist"
      find_by!(cohort:, identifier: "npq-specialist-spring")
    when "leadership"
      find_by!(cohort:, identifier: "npq-leadership-spring")
    when "support"
      find_by!(cohort:, identifier: "npq-aso-december")
    when "ehco"
      find_by!(cohort:, identifier: "npq-ehco-june")
    end
  end
end
