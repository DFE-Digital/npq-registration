require "csv"

namespace :eyl_eligible_schools do
  desc "Make schools eligible for NPQEYL courses"
  task :update, %i[file_name] => :environment do |_t, args|
    updated_records = 0
    update_errors = 0
    file_name = args.file_name

    raise "File not found: #{file_name}" unless File.exist?(file_name)

    Rails.logger.info("Updating schools from CSV file: #{file_name}")

    table = CSV.parse(File.read(file_name), headers: true)

    table.each do |row|
      gias_urn = row["gias_urn"]

      school = School.find_by(urn: gias_urn)

      if school.nil?
        update_errors += 1
        Rails.logger.error("Failed to update school with GIAS URN: #{gias_urn}")
      else
        school&.update!(eyl_eligible: true)
        updated_records += 1
      end
    end

    Rails.logger.info("Update finished")

    Rails.logger.info("Updated Records: #{updated_records}")
    Rails.logger.info("Update Errors: #{update_errors}")
  end
end
