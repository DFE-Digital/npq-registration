module CourseGroups
  class Specialist
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :course_group
    attribute :cohort
    attribute :schedule_date, :date

    delegate :schedules, to: :course_group

    def schedule
      if autumn_schedule_2022?(schedule_date)
        schedules.find_by!(cohort:, identifier: "npq-specialist-autumn")
      elsif autumn_schedule_2024?(schedule_date)
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

    def autumn_schedule_2022?(date)
      # Between: 1st Jun 2022 and 25th Dec 2022
      (Date.new(2022, 6, 1)..Date.new(2022, 12, 25)).include?(date)
    end

    def autumn_schedule_2024?(date)
      # Between: 28th June 2024 and 6th June 2025
      (Date.new(2024, 6, 28)..Date.new(2025, 6, 6)).include?(date)
    end

    def spring_schedule?(date)
      # Between: 1st Jan and 2nd Apr
      # Or between: 26th Dec and 31st Dec
      (Date.new(date.year, 1, 1)..Date.new(date.year, 4, 2)).include?(date) ||
        (Date.new(date.year, 12, 26)..Date.new(date.year, 12, 31)).include?(date)
    end

    def autumn_schedule?(date)
      # Between: 3rd Apr and 25th Dec
      (Date.new(date.year, 4, 3)..Date.new(date.year, 12, 25)).include?(date)
    end
  end
end
