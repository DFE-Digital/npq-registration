namespace :tad_requests do
  desc "Generate TAD request for Spring 2025 for SENCO"

  task spring_2025_senco: :environment do
    cohort = Cohort.find_by(start_year: 2025)
    schedules = Schedule.where(identifier: %w[npq-specialist-spring npq-leadership-spring], cohort:)

    File.open("tmp/spring_2025_senco.csv", "w") do |f|
      exporter = Exporters::TadSencoDataRequest.new(cohort:, schedules:, file: f)
      exporter.call
    end
  end
end
