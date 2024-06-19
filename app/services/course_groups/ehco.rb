module CourseGroups
  class Ehco
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :course_group
    attribute :cohort
    attribute :schedule_date, :date

    delegate :schedules, to: :course_group

    def schedule
      return schedules.find_by!(cohort:) unless cohort_with_multiple_schedules?

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

    def cohort_with_multiple_schedules?
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
end
