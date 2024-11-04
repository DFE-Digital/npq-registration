require "csv"

namespace :legacy_participant_outcomes do
  desc "Import DQT data from CSV file"
  task :import, %i[file_path] => :environment do |_t, args|
    file_path = args[:file_path]

    puts "Importing file #{file_path}"
    CSV.foreach(File.expand_path(file_path), headers: true, header_converters: :symbol) do |row|
      LegacyPassedParticipantOutcome.create!(trn: row[:trn], course_short_code: row[:npq_type], completion_date: Date.strptime(row[:awarded_date], "%m/%d/%Y"))
    end

    puts "Import finished"
  end
end
