require "csv"

namespace :update_eyl_funding_eligible_schools_list do
  desc "Make schools funding eligible for NPQEYL courses"
  task :update, %i[file_name] => :environment do |_t, args|
    file_name = args.file_name
    previous_file = "lib/eyl_funding_eligible_schools/2022-11-30/eligible-schools.csv"

    raise "File not found: #{file_name}" unless File.exist?(file_name)
    raise "File not found: #{previous_file}" unless File.exist?(previous_file)

    Rails.logger.info("Fetching previous schools from CSV file: #{previous_file}")

    previous_school_urns = CSV.parse(File.read(previous_file), headers: true).map { |row| row["gias_urn"] }

    Rails.logger.info("Fetched Records: #{previous_school_urns.count}")

    Rails.logger.info("Updating schools from CSV file: #{file_name}")

    updated_current_records = []

    CSV.foreach(file_name, headers: true) do |row|
      gias_urn = row["gias_urn"]
      school = School.find_by(urn: gias_urn)

      if school.nil?
        postcode = row["EstablishmentPostcode"]
        existing_school = School.find_by(postcode:)
        if existing_school.present?
          school = existing_school.dup
          school_name = row["EstablishmentName"]
          school.update!(name: school_name, urn: gias_urn, eyl_funding_eligible: true, establishment_status_code: 1, establishment_status_name: "Open", postcode:)
        end
      else
        school&.update!(eyl_funding_eligible: true, establishment_status_code: 1, establishment_status_name: "Open")
        updated_current_records << school.urn
      end
    end

    Rails.logger.info("Update finished")

    Rails.logger.info("Updated Records: #{updated_current_records.count}")

    closed_school_urns = previous_school_urns - updated_current_records

    School.transaction do
      School.where(urn: closed_school_urns).update_all(establishment_status_code: 2, establishment_status_name: "Closed")
    end
    private_childcare_provider = PrivateChildcareProvider.find_by(postcode: 'SW6 3AA')
    PrivateChildcareProvider.create!(provider_urn: '100547',provider_name: "ECOLE MARIE D'ORLIAC", postcode: 'SW6 3AA') unless private_childcare_provider.present?
  end
end
