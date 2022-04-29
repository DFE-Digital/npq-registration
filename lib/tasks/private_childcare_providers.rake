namespace :private_childcare_providers do
  desc "Sync applications attributes with ecf service"
  task :import, [:file_name] => :environment do |_t, args|
    file_name = args.file_name
    Rails.logger.info("Importing Childcare providers from CSV file: #{file_name}")

    importer = Services::PrivateChildcareProviders::Importer.new(file_name: file_name)

    importer.call

    Rails.logger.info("Import finished")

    Rails.logger.info("Imported Records: #{importer.imported_records}")
    Rails.logger.info("Import Errors: #{importer.import_errors}")
  end
end
