namespace :tad_requests do
  desc "Generate TAD request for Autumn 2023 for NPQEYL, NPQEL, NPQH, NPQSL"

  task autumn_2023: :environment do
    course_identifiers = [
      "npq-senior-leadership", # NPQSL,
      "npq-headship", # NPQH
      "npq-executive-leadership", # NPQEL
      "npq-early-years-leadership", # NPQEYL
    ].freeze

    cohort = Cohort.find_by(start_year: 2023)
    schedules = Schedule.where(identifier: %w[npq-specialist-autumn npq-leadership-autumn], cohort:)
    courses = Course.where(identifier: course_identifiers)

    File.open("/tmp/autumn_2023.csv", "w") do |f|
      exporter = Exporters::TadDataRequest.new(cohort:, schedules:, courses:, file: f)
      exporter.call
    end
  end
end
