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
        logger.info "Removing old records"
        LegacyPassedParticipantOutcome.destroy_all

        logger.info "Importing file #{file_path}"
        CSV.foreach(File.expand_path(file_path), headers: true, header_converters: :symbol) do |row|
          LegacyPassedParticipantOutcome.create!(trn: row[:trn], course_short_code: row[:npq_type], completion_date: Date.strptime(row[:awarded_date], "%m/%d/%Y"))
        end
        raise ActiveRecord::Rollback if dry_run
      end

      logger.info "Import finished"
    end
  end
end
