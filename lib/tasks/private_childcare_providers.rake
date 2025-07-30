# How to use this importer:
# 1. Download the files, as described in docs/acquiring_new_private_childcare_provider_data.md
# 2. commit the files into the repo, in a lib/private_childcare_providers/YYYY-MM-DD directory
#
# Run examples:
# rake 'private_childcare_providers:import[lib/private_childcare_providers/2025-03-31/childminder_agencies.csv,childminder_agencies]'
# rake 'private_childcare_providers:import[lib/private_childcare_providers/2025-03-31/childcare_providers.csv,childcare_providers]'
namespace :private_childcare_providers do
  desc "Sync PrivateChildcareProvider attributes with imported file"
  task :import, %i[file_name parser] => :environment do |_t, args|
    file_name = args.file_name
    parser = args.parser
    logger = Rails.env.test? ? Rails.logger : Logger.new($stdout)

    logger.info("Importing Childcare providers from CSV file: #{file_name}")

    importer = Importers::ImportPrivateChildcareProviders
    csv_row_parser = case parser
                     when "childminder_agencies"
                       importer::ChildminderAgencyWrappedCSVRow
                     when "childcare_providers"
                       importer::ChildcareProviderWrappedCSVRow
                     end

    if csv_row_parser.blank?
      raise NotImplementedError, "Missing parser option, please choose either childminder_agencies or childcare_providers"
    end

    logger.info("Parsing CSV file using: #{csv_row_parser}")

    importer = importer.new(file_name:, csv_row_parser:)
    importer.call

    logger.info("Import finished")
    logger.info("Imported Records: #{importer.imported_records}")
    logger.info("Updated Records: #{importer.updated_records}")
    logger.info("Import Errors: #{importer.import_errors}")
  end
end
