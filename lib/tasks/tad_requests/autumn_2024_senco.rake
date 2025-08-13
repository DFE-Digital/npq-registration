namespace :tad_requests do
  desc "Generate TAD request for Autumn 2024 for SENCO"

  task autumn_2024_senco: :environment do
    cohort = Cohort.find_by(start_year: 2024)
    schedules = Schedule.where(identifier: %w[npq-specialist-autumn npq-leadership-autumn], cohort:)

    File.open("tmp/autumn_2024_senco.csv", "w") do |f|
      exporter = Exporters::TadSencoDataRequest.new(cohort:, schedules:, file: f)
      exporter.call
    end
  end
end
