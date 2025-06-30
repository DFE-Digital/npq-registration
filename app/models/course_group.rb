class CourseGroup < ApplicationRecord
  has_many :courses
  has_many :schedules

  validates :name, presence: true, uniqueness: true

  scope :leadership_or_specialist, -> { where(name: %w[leadership specialist]) }

  def schedule_for(cohort:, schedule_date:)
    case name
    when "leadership"
      CourseGroups::Leadership.new(course_group: self, cohort:, schedule_date:).schedule
    when "specialist"
      CourseGroups::Specialist.new(course_group: self, cohort:, schedule_date:).schedule
    when "support"
      CourseGroups::Support.new(course_group: self, cohort:).schedule
    when "ehco"
      CourseGroups::Ehco.new(course_group: self, cohort:, schedule_date:).schedule
    else
      raise ArgumentError, "Invalid course group name"
    end
  end
end
