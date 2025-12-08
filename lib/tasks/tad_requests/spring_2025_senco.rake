namespace :tad_requests do
  desc "Generate TAD request for Spring 2025 for SENCO"

  task spring_2025_senco: :environment do
    cohort = Cohort.find_by!(identfier: "2025a")

    File.open("tmp/spring_2025_senco.csv", "w") do |f|
      exporter = Exporters::TadSencoDataRequest.new(cohort:, file: f)
      exporter.call
    end
  end
end
