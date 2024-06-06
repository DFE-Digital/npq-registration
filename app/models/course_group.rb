class CourseGroup < ApplicationRecord
  has_many :courses
  has_many :schedules

  validates :name, presence: { message: "Enter a unique course group name" }, uniqueness: { message: "Course name already exist, enter a unique name" }

  def schedule_for(cohort: Cohort.current, schedule_date: Date.current)
    case name
    when "leadership"
      leadership_schedule_for(cohort:, schedule_date:)
    when "specialist"
      specialist_schedule_for(cohort:, schedule_date:)
    when "support"
      support_schedule_for(cohort:)
    when "ehco"
      ehco_schedule_for(cohort:, schedule_date:)
    else
      raise ArgumentError, "Invalid course group name"
    end
  end

  def leadership_schedule_for(cohort:, schedule_date:)
    if autumn_schedule_2022?(schedule_date)
      schedules.find_by!(cohort:, identifier: "npq-leadership-autumn")
    elsif spring_schedule?(schedule_date)
      schedules.find_by!(cohort:, identifier: "npq-leadership-spring")
    elsif autumn_schedule?(schedule_date)
      schedules.find_by!(cohort:, identifier: "npq-leadership-autumn")
    else
      # Default
      schedules.find_by!(cohort:, identifier: "npq-leadership-spring")
    end
  end

  def specialist_schedule_for(cohort:, schedule_date:)
    if autumn_schedule_2022?(schedule_date)
      schedules.find_by!(cohort:, identifier: "npq-specialist-autumn")
    elsif spring_schedule?(schedule_date)
      schedules.find_by!(cohort:, identifier: "npq-specialist-spring")
    elsif autumn_schedule?(schedule_date)
      schedules.find_by!(cohort:, identifier: "npq-specialist-autumn")
    else
      # Default
      schedules.find_by!(cohort:, identifier: "npq-specialist-spring")
    end
  end

  def support_schedule_for(cohort:)
    # Default
    schedules.find_by!(cohort:, identifier: "npq-aso-december")
  end

  def ehco_schedule_for(cohort:, schedule_date:)
    return schedules.find_by!(cohort:) unless cohort_with_multiple_schedules?(cohort)

    case schedule_date
    when first_day_of_september_current_year(cohort.start_year)..last_day_of_november_current_year(cohort.start_year)
      schedules.find_by!(cohort:, identifier: "npq-ehco-november")
    when first_day_of_december_current_year(cohort.start_year)..last_day_of_february_next_year(cohort.start_year)
      schedules.find_by!(cohort:, identifier: "npq-ehco-december")
    when first_day_of_march_next_year(cohort.start_year)..last_day_of_may_next_year(cohort.start_year)
      schedules.find_by!(cohort:, identifier: "npq-ehco-march")
    when first_day_of_june_next_year(cohort.start_year)..last_day_of_september_next_year(cohort.start_year)
      schedules.find_by!(cohort:, identifier: "npq-ehco-june")
    else
      # Default
      schedules.find_by!(cohort:, identifier: "npq-ehco-june")
    end
  end

  def autumn_schedule_2022?(date)
    # Between: Jun 1 to Dec 25
    (Date.new(2022, 6, 1)..Date.new(2022, 12, 25)).include?(date)
  end

  def spring_schedule?(date)
    # Between: Jan 1 to Apr 2
    # Or between: Dec 26 to Dec 31
    (Date.new(date.year, 1, 1)..Date.new(date.year, 4, 2)).include?(date) ||
      (Date.new(date.year, 12, 26)..Date.new(date.year, 12, 31)).include?(date)
  end

  def autumn_schedule?(date)
    # Between: Apr 3 to Dec 25
    (Date.new(date.year, 4, 3)..Date.new(date.year, 12, 25)).include?(date)
  end

  def cohort_with_multiple_schedules?(cohort)
    (2022..).include?(cohort.start_year)
  end

  def first_day_of_september_current_year(cohort_start_year)
    Date.new(cohort_start_year, 9, 1)
  end

  def last_day_of_november_current_year(cohort_start_year)
    Date.new(cohort_start_year, 11, -1)
  end

  def first_day_of_december_current_year(cohort_start_year)
    Date.new(cohort_start_year, 12, 1)
  end

  def last_day_of_february_next_year(cohort_start_year)
    Date.new(cohort_start_year + 1, 2, -1)
  end

  def first_day_of_march_next_year(cohort_start_year)
    Date.new(cohort_start_year + 1, 3, 1)
  end

  def last_day_of_may_next_year(cohort_start_year)
    Date.new(cohort_start_year + 1, 5, -1)
  end

  def first_day_of_june_next_year(cohort_start_year)
    Date.new(cohort_start_year + 1, 6, 1)
  end

  def last_day_of_september_next_year(cohort_start_year)
    Date.new(cohort_start_year + 1, 9, -1)
  end
end
