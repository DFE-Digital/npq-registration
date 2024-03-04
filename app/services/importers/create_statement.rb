require "csv"

module Importers
  class CreateStatement < BaseService
    def call
      check_headers!

      logger.info "CreateStatement: Started!"

      ActiveRecord::Base.transaction do
        create_statements!
      end

      logger.info "CreateStatement: Finished!"
    end

  private

    attr_reader :path_to_csv, :logger

    def initialize(path_to_csv:, logger: Rails.logger)
      @path_to_csv = path_to_csv
      @logger = logger
    end

    def create_statements!
      statements.each do |statement_data|
        lead_providers.each do |lead_provider|
          logger.info "CreateStatement: Creating #{statement_data.cohort.start_year} cohort NPQ statements for #{lead_provider.name}"

          statement = Statement.find_by(
            month: statement_data.month,
            year: statement_data.year,
            lead_provider:,
            cohort: statement_data.cohort,
          )

          next if statement

          Statement.create!(
            month: statement_data.month,
            year: statement_data.year,
            lead_provider:,
            deadline_date: statement_data.deadline_date,
            payment_date: statement_data.payment_date,
            cohort: statement_data.cohort,
            output_fee: statement_data.output_fee,
          )

          logger.info "CreateStatement: #{statement_data.cohort.start_year} cohort statements for #{lead_provider.name} successfully created!"
        end
      end
    end

    def statement_converter
      lambda do |value, field_info|
        case field_info.header
        when "deadline_date", "payment_date"
          Date.parse(value)
        when "output_fee"
          ActiveModel::Type::Boolean.new.cast(value)
        when "cohort"
          Cohort.find_by!(start_year: value)
        else
          value
        end
      end
    end

    def check_headers!
      unless %w[month year deadline_date payment_date output_fee cohort].all? { |header| rows.headers.include?(header) }
        raise NameError, "Invalid headers"
      end
    end

    def rows
      @rows ||= CSV.read(
        path_to_csv,
        headers: true,
        skip_blanks: true,
        converters: [statement_converter],
      )
    end

    def statements
      @statements ||= rows.map { |hash| OpenStruct.new(hash) }
    end

    def lead_providers
      @lead_providers ||= LeadProvider.all
    end
  end
end
