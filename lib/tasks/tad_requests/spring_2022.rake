namespace :tad_requests do
  desc "Generate TAD request for Spring 2022 for NPQEYL, NPQEL, NPQH, NPQSL"

  task spring_2022: :environment do
    course_identifiers = [
      "npq-senior-leadership", # NPQSL,
      "npq-headship", # NPQH
      "npq-executive-leadership", # NPQEL
      "npq-early-years-leadership", # NPQEYL
    ].freeze

    cohort = Cohort.find_by!(identifier: "2022-1")
    schedules = Schedule.where(identifier: %w[npq-leadership-spring npq-specialist-spring], cohort:)
    courses = Course.where(identifier: course_identifiers)

    File.open("/tmp/spring_2022.csv", "w") do |f|
      exporter = Exporters::TadDataRequest.new(cohort:, schedules:, courses:, file: f)
      exporter.call
    end
  end
end
