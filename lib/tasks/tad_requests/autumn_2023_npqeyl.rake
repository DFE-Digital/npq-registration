namespace :tad_requests do
  desc "Generate TAD request for NPQEYL for Autumn 2023"

  task autumn_2023_npqeyl: :environment do
    cohort = Cohort.find_by!(identifier: "2023-1")
    schedules = Schedule.where(cohort:, identifier: "npq-leadership-autumn")
    courses = Course.where(identifier: "npq-early-years-leadership")

    File.open("tmp/autumn_2023_npqeyl.csv", "w") do |f|
      exporter = Exporters::TadDataRequest.new(cohort:, schedules:, courses:, file: f)
      exporter.call
    end
  end
end
