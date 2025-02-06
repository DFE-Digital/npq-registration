# How to use this importer:
# 1. download the CSV files from the statistics page:
#      e.g. https://www.gov.uk/government/statistical-data-sets/childcare-providers-and-inspections-management-information
#      childcare providers: Management_information_-_childcare_providers_and_inspections_-_most_recent_inspections_data_-_as_at_31_December_2024.csv
#      childminder agencies: Management_information_-_childcare_providers_and_inspections_-_registered_childminder_agencies_as_at_31_December_2024.csv
# 2. rename the files to childcare_providers.csv and childminder_agencies.csv
# 3. delete the non-header rows from the files - the first line should be the CSV header
# 4. commit the files into the repo, in a lib/private_childcare_providers/YYYY-MM-DD directory
#
# Run examples:
# rake 'private_childcare_providers:import[lib/private_childcare_providers/2024-12-31/childminder_agencies.csv,childminder_agencies]'
# rake 'private_childcare_providers:import[lib/private_childcare_providers/2024-12-31/childcare_providers.csv,childcare_providers]'
namespace :private_childcare_providers do
  desc "Sync PrivateChildcareProvider attributes with imported file"
  task :import, %i[file_name parser] => :environment do |_t, args|
    file_name = args.file_name
    parser = args.parser
    Rails.logger.info("Importing Childcare providers from CSV file: #{file_name}")

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

    Rails.logger.info("Parsing CSV file using: #{csv_row_parser}")

    importer = importer.new(file_name:, csv_row_parser:)

    importer.call

    Rails.logger.info("Import finished")

    Rails.logger.info("Imported Records: #{importer.imported_records}")
    Rails.logger.info("Updated Records: #{importer.updated_records}")
    Rails.logger.info("Import Errors: #{importer.import_errors}")
  end
end
