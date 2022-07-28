require "csv"

class Services::Importers::ManualValidation
  class InvalidHeadersError < NameError; end

  attr_reader :path_to_csv

  def initialize(path_to_csv:)
    @path_to_csv = path_to_csv
  end

  def call
    check_headers

    skipped = []
    updated = 0

    rows.each do |row|
      application = Application.includes(:user).find_by(ecf_id: row["application_ecf_id"])

      Rails.logger.info("no application found for #{row['application_ecf_id']}") if application.nil?

      (skipped << row["application_ecf_id"]) and next if application.nil?

      Rails.logger.info("updating trn for application: #{row['application_ecf_id']} with trn: #{row['validated_trn']}")

      application.user.update!(trn: row["validated_trn"], trn_verified: true)
      updated += 1
    end

    { skipped:, updated: }
  end

private

  def check_headers
    unless rows.headers == %w[application_ecf_id validated_trn]
      raise InvalidHeadersError, "Invalid headers"
    end
  end

  def rows
    @rows ||= CSV.read(path_to_csv, headers: true)
  end
end
