# Note before running, the file when downloaded from the correct link will need to be edited
# the top three lines and the first column are note used and then you have to make sure the
# top row is a header line as sometimes when converting it from .ods espeically on macs you
# you may come across issues with first line causing the problem. Also the file you are
# looking for is called "Childcare provider level data as at.."

# https://www.gov.uk/government/statistics/childcare-providers-and-inspections-as-at-31-march-2022

# Run examples:
# bundle exec rake 'private_childcare_providers:import[lib/private_childcare_providers/2022-08-31/childcare_providers.csv,childcare_providers]'

namespace :private_childcare_providers do
  desc "Sync applications attributes with ecf service"
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
