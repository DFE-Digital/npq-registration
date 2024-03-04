require "csv"

module Importers
  class CreateCohort < BaseService
    def call
      check_headers!

      logger.info "CreateCohort: Started!"

      ActiveRecord::Base.transaction do
        rows.each do |row|
          create_cohort(row)
        end
      end

      logger.info "CreateCohort: Finished!"
    end

  private

    attr_reader :path_to_csv, :logger

    def initialize(path_to_csv:, logger: Rails.logger)
      @path_to_csv = path_to_csv
      @logger = logger
    end

    def create_cohort(row)
      start_year = row["start-year"].to_i
      logger.info "CreateCohort: Creating cohort for starting year #{start_year}"

      cohort = Cohort.find_by(start_year:)

      return if cohort

      Cohort.create!(
        start_year:,
        registration_start_date: safe_parse(row["registration-start-date"]),
        created_at: Time.zone.now,
        updated_at: Time.zone.now,
      )

      logger.info "CreateCohort: Cohort for starting year #{start_year} successfully created"
    end

    def safe_parse(date)
      return if date.blank?

      Date.parse(date)
    rescue Date::Error
      logger.warn "CreateCohort: Error parsing date"
      nil
    end

    def check_headers!
      unless %w[start-year registration-start-date].all? { |header| rows.headers.include?(header) }
        raise NameError, "Invalid headers"
      end
    end

    def rows
      @rows ||= CSV.read(path_to_csv, headers: true)
    end
  end
end
