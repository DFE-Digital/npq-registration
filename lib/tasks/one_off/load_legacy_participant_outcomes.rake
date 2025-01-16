require "csv"

namespace :one_off do
  namespace :legacy_participant_outcomes do
    desc "Import DQT data from CSV file (has header: trn,npq_type,awarded_date and the date is in format m/d/Y)"
    task :import, %i[file_path dry_run] => :environment do |_t, args|
      logger = Logger.new($stdout)
      file_path = args[:file_path]
      dry_run = args[:dry_run] != "false"
      unless File.exist?(file_path)
        logger.error "File not found: #{file_path}"
        exit 1
      end

      ActiveRecord::Base.transaction do
        logger.info "Removing #{LegacyPassedParticipantOutcome.count} old records"
        LegacyPassedParticipantOutcome.destroy_all

        dqt_npq_type_id_to_npq_short_code = {
          "389040001" => "NPQH",
          "389040004" => "NPQSL",
          "389040005" => "NPQML", # this short code does not exist in NPQ (NPQ for Middle Leadership)
          "389040006" => "NPQEL",
          "389040007" => "NPQLT",
          "389040008" => "NPQLTD",
          "389040009" => "NPQLBC",
          "389040010" => "NPQEYL",
          "389040011" => "NPQLL",
        }

        logger.info "Importing file #{file_path}"
        CSV.foreach(File.expand_path(file_path), headers: true, header_converters: :symbol) do |row|
          course_short_code = dqt_npq_type_id_to_npq_short_code[row[:npq_type]]
          raise "Unknown NPQ type: #{row[:npq_type]}" unless course_short_code

          LegacyPassedParticipantOutcome.create!(
            trn: row[:trn],
            course_short_code: course_short_code,
            completion_date: Date.strptime(row[:awarded_date], "%m/%d/%Y"),
          )
        end

        logger.info "Rows loaded, now committing transaction (may take a few minutes)" unless dry_run
        raise ActiveRecord::Rollback if dry_run
      end

      logger.info "Import finished"
      logger.info "#{LegacyPassedParticipantOutcome.count} records imported"
    end
  end
end
