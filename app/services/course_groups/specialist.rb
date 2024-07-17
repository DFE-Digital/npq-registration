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
  end
end
