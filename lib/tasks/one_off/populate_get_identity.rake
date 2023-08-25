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

  desc "Check validity of get_identity_id import"
  task :check, %i[file_path] => :environment do |_t, args|
    file_path = args[:file_path]

    rows = []
    Rails.logger.info("Checking file #{file_path}")
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      rows << row
      attrs = row.to_h

      user_id = attrs.fetch(:user_id)
      user = User.find_by(id: user_id)

      Rails.logger.error("User #{user_id} not found") if user.nil?
      Rails.logger.error("User #{user_id} has no ECF ID") if user.ecf_id.nil?
      Rails.logger.error("User #{user_id} with existing GIA? -> (#{user.uid != attrs.fetch(:id)})") if user.uid.present?

      Rails.logger.info(".")
    end
    Rails.logger.info("Check finished: #{rows.count} rows checked")
  end
end
