# frozen_string_literal: true

class FundingEligibilityData
  class << self
    delegate :rise_school?, to: :instance

    def instance
      @instance ||= new
    end
  end

  def initialize(data_file_path = default_data_file_path)
    @data_file_path = data_file_path
  end

  def rise_school?(school_or_urn)
    urn = school_or_urn.is_a?(School) ? school_or_urn.urn : school_or_urn

    rise_urns.include?(urn.to_i)
  end

  def rise_urns
    @rise_urns ||= load_rise_urns
  end

private

  def default_data_file_path
    if Rails.env.test?
      Rails.root.join("spec/fixtures/files")
    else
      Rails.root.join("config/data/autumn_2025")
    end
  end

  def load_rise_urns
    Set.new.tap do |rise_urns|
      CSV.read(@data_file_path.join("rise.csv"), headers: true).each do |row|
        rise_urns << row["School URN"].to_i
      end
    end
  end
end
