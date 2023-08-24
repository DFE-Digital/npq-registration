require "csv"

namespace :get_identity_id do
  desc "Import get_identity_id from CSV file"
  task :import, %i[file_path] => :environment do |_t, args|
    file_path = args[:file_path]

    rows = []
    Rails.logger.info("Importing file #{file_path}")
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      rows << row.to_h
    end

    importer = Services::Importers::PopulateGetIdentityId.new
    importer.import(rows)

    Rails.logger.info("Import finished")
  end
end
