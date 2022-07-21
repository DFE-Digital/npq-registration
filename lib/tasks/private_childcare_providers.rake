namespace :private_childcare_providers do
  desc "Sync applications attributes with ecf service"
  task :import, %i[file_name parser] => :environment do |_t, args|
    file_name = args.file_name
    parser = args.parser
    Rails.logger.info("Importing Childcare providers from CSV file: #{file_name}")

    importer = Services::PrivateChildcareProviders::Importer
    csv_row_parser = case parser
                     when "childminder_agencies"
                       importer::ChildminderAgencyWrappedCSVRow
                     when "childcare_providers"
                       importer::ChildcareProviderWrappedCSVRow
                     end

    if csv_row_parser.blank?
      raise NotImplementedError, "Missing parser option, please choose either childminder_agencies or childcare_providers"
    end

    Rails.logger.info("Parsing CSV file using: #{csv_row_parser}")

    importer = importer.new(file_name:, csv_row_parser:)

    importer.call

    Rails.logger.info("Import finished")

    Rails.logger.info("Imported Records: #{importer.imported_records}")
    Rails.logger.info("Updated Records: #{importer.updated_records}")
    Rails.logger.info("Import Errors: #{importer.import_errors}")
  end
end
