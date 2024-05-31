require "csv"

class AddSchedules
  attr_reader :path_to_csv

  def initialize(path_to_csv:)
    @path_to_csv = path_to_csv
  end

  def call
    rows.each do |row|
      course_group = CourseGroup.find_by!(name: row["course-group-name"])
      cohort = Cohort.find_by!(start_year: row["schedule-cohort-year"].to_i)

      schedule = Schedule.find_or_initialize_by(
        identifier: row["schedule-identifier"],
        cohort:,
      )

      schedule.course_group = course_group
      schedule.name = row["schedule-name"]
      schedule.applies_from = row["schedule-applies-from"]
      schedule.applies_to = row["schedule-applies-to"]
      schedule.allowed_declaration_types = row["declaration-types"].split("|")

      schedule.save!
    end
  end

  def rows
    @rows ||= CSV.read(
      path_to_csv,
      headers: true,
      skip_blanks: true,
    )
  end
end

AddSchedules.new(path_to_csv: Rails.root.join("db/seeds/schedules.csv")).call
