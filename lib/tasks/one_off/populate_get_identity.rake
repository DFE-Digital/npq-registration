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

      application_id = attrs.fetch(:id)
      application = Application.find_by(ecf_id: application_id)
      Rails.logger.error("Application #{application_id} not found") if application.nil?

      if application
        user = application.user

        Rails.logger.error("User not found") if user.nil?

        get_identity_id = attrs.fetch(:user_id)
        if user && user.uid.present? && user.uid != get_identity_id
          Rails.logger.error("User #{user.id} #{user.email} with existing GIA? different -> (#{user.uid != get_identity_id})")
        end
        if user && user.uid.blank? && User.find_by(uid: get_identity_id).present?
          Rails.logger.error("User UID #{get_identity_id} linked to a different user")
        end
      end
    end
    Rails.logger.info("Check finished: #{rows.count} rows checked")
  end
end
