require "csv"

class Importers::LocalAuthorities
  attr_reader :path_to_csv

  def initialize(path_to_csv:)
    @path_to_csv = path_to_csv
  end

  def call
    check_headers

    rows.each do |row|
      la = LocalAuthority.find_or_initialize_by(ukprn: row["ukprn"])

      la.update!(
        name: row["name"],
        address_1: row["address_1"],
        address_2: row["address_2"],
        address_3: row["address_3"],
        town: row["town"],
        county: row["county"],
        postcode: row["postcode"],
        postcode_without_spaces: row["postcode"]&.gsub(" ", ""),
        high_pupil_premium: ActiveModel::Type::Boolean.new.cast(row["high_pupil_premium"]),
      )
    end
  end

private

  def rows
    @rows ||= CSV.read(path_to_csv, headers: true)
  end

  def check_headers
    unless rows.headers == %w[ukprn name address_1 address_2 address_3 town county postcode high_pupil_premium]
      raise NameError, "Invalid headers"
    end
  end
end
