require "csv"

class Services::Importers::ManualValidation
  attr_reader :path_to_csv

  def initialize(path_to_csv:)
    @path_to_csv = path_to_csv
  end

  def call
    check_headers

    rows.each do |row|
      application = Application.includes(:user).find_by(ecf_id: row["application_ecf_id"])

      puts "no application found for #{row['application_ecf_id']}" if application.nil?
      next if application.nil?

      puts "updating trn for application: #{row['application_ecf_id']} with trn: #{row['validated_trn']}"

      application.user.update!(trn: row["validated_trn"], trn_verified: true)
    end
  end

private

  def check_headers
    unless rows.headers == %w[application_ecf_id validated_trn]
      raise NameError, "Invalid headers"
    end
  end

  def rows
    @rows ||= CSV.read(path_to_csv, headers: true)
  end
end
