namespace :tad_requests do
  desc "Generate TAD request for Autumn 2023 for NPQLL"

  task autumn_2023_npqll: :environment do
    course_identifiers = [
      "npq-leading-literacy", # NPQLL,
    ].freeze

    cohort = Cohort.find_by!(identifier: "2023-1")
    schedules = Schedule.where(identifier: %w[npq-specialist-autumn npq-leadership-autumn], cohort:)
    courses = Course.where(identifier: course_identifiers)

    File.open("/tmp/autumn_2023_npqll.csv", "w") do |f|
      exporter = Exporters::TadDataRequest.new(cohort:, schedules:, courses:, file: f)
      exporter.call
    end
  end
end
