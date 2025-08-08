# frozen_string_literal: true

class FundingEligibilityData
  def initialize(data_file_path = default_data_file_path)
    @data_file_path = data_file_path
  end

  def rise_school?(school_or_urn)
    urn = school_or_urn.is_a?(School) ? school_or_urn.urn : school_or_urn

    rise_data.key?(urn.to_i)
  end

private

  def default_data_file_path
    if Rails.env.test?
      Rails.root.join("spec/fixtures/files")
    else
      Rails.root.join("config/data/autumn_2025")
    end
  end

  def rise_data
    @rise_data ||= load_rise_data
  end

  def load_rise_data
    {}.tap do |rise_data|
      CSV.read(@data_file_path.join("rise.csv"), headers: true).each do |row|
        rise_data[row["School URN"].to_i] = row.to_h
      end
    end
  end
end
