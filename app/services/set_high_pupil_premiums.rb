require "csv"

class SetHighPupilPremiums
  attr_reader :path_to_csv

  def initialize(path_to_csv:)
    @path_to_csv = path_to_csv
  end

  def call
    School.where(urn: urns).update_all(high_pupil_premium: true)
  end

private

  def rows
    CSV.read(path_to_csv, headers: true)
  end

  def urns
    @urns ||= rows["urn"]
  end
end
