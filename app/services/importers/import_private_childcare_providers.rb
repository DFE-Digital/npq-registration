require "csv"

module Importers
  class ImportPrivateChildcareProviders
    attr_reader :file_name, :import_errors, :imported_records, :updated_records, :csv_row_parser

    def initialize(file_name:, csv_row_parser:)
      @file_name = file_name
      @import_errors = {}
      @imported_records = 0
      @updated_records = 0
      @csv_row_parser = csv_row_parser
    end

    def call
      raise_not_found_error unless file_exists?

      check_header_valid

      CSV.foreach(file_name, **csv_options).with_index(&method(:persist_csv_row))
    end

  private

    def check_header_valid
      header = CSV.open(file_name, "r:ISO-8859-1", &:first).compact.map(&:downcase)
      missing_columns = csv_row_parser.columns.values - header
      unless missing_columns.empty?
        raise "Header invalid: missing columns #{missing_columns.join(", ")}"
      end
    end

    def raise_not_found_error
      raise "File not found: #{file_name}"
    end

    def file_exists?
      File.exist?(file_name)
    end

    def csv_options
      {
        headers: true,
        col_sep: ",",
        quote_char: '"',
        encoding: "ISO-8859-1",
        header_converters: ->(header) { header&.downcase },
      }
    end

    def file
      @file ||= CSV.open(file_name)
    end

    PROVIDER_URN_HEADER_NAME = "Provider URN".freeze

    def persist_csv_row(csv_row, row_number)
      wrapped_csv_row = csv_row_parser.new(csv_row:)

      new_record = false
      updated_record = false

      private_childcare_provider = PrivateChildcareProvider.find_or_initialize_by(provider_urn: wrapped_csv_row.column(:provider_urn)) do
        new_record = true
      end

      private_childcare_provider.assign_attributes(
        address_1: wrapped_csv_row.column(:address_1),
        address_2: wrapped_csv_row.column(:address_2),
        address_3: wrapped_csv_row.column(:address_3),
        provider_status: wrapped_csv_row.column(:provider_status),
        early_years_individual_registers: wrapped_csv_row.early_years_individual_registers,
        local_authority: wrapped_csv_row.column(:local_authority),
        ofsted_region: wrapped_csv_row.column(:ofsted_region),
        places: wrapped_csv_row.column(:places),
        postcode: strip_whitespace(wrapped_csv_row.column(:postcode)),
        postcode_without_spaces: strip_whitespace(wrapped_csv_row.postcode_without_spaces),
        provider_compulsory_childcare_register_flag: wrapped_csv_row.provider_compulsory_childcare_register_flag,
        provider_early_years_register_flag: wrapped_csv_row.provider_early_years_register_flag,
        provider_name: translate_unicode_characters(wrapped_csv_row.column(:provider_name)),
        region: wrapped_csv_row.column(:region),
        registered_person_name: wrapped_csv_row.column(:registered_person_name),
        registered_person_urn: wrapped_csv_row.column(:registered_person_urn),
        registration_date: wrapped_csv_row.column(:registration_date),
        town: wrapped_csv_row.column(:town),
      )

      updated_record = private_childcare_provider.changed? unless new_record

      private_childcare_provider.save!

      @imported_records += 1 if new_record
      @updated_records += 1 if updated_record
    rescue StandardError => e
      # I've adjusted the row in the error here so that it'll properly line up with spreadsheeting software
      # when hunting for errors.
      # It's +2 because we need +1 to account for headers, and +1 to account for with_index being zero based.
      row_number_for_errors = row_number + 2
      @import_errors[row_number_for_errors] = []
      @import_errors[row_number_for_errors] << e.message
    end

    def translate_unicode_characters(string)
      string.tr("\u0096", "\u2013")
    end

    def strip_whitespace(string)
      string.gsub(/\A\p{Space}+|\p{Space}+\z/, "")
    end

    class ChildcareProviderWrappedCSVRow
      attr_reader :csv_row

      def self.columns
        {
          provider_urn: "provider urn",
          provider_name: "provider name",
          registered_person_name: "registered person name",
          registered_person_urn: "registered person urn",
          registration_date: "registration date",
          provider_status: "provider status",
          address_1: "provider address line 1",
          address_2: "provider address line 2",
          address_3: "provider address line 3",
          town: "provider town",
          postcode: "postcode",
          region: "region",
          local_authority: "local authority",
          ofsted_region: "ofsted region",
          places: "places",
          early_years_individual_registers: "individual register combinations",
          provider_compulsory_childcare_register_flag: "provider compulsory childcare register flag",
          provider_early_years_register_flag: "provider early years register flag",
        }
      end

      def initialize(csv_row:)
        @csv_row = csv_row
      end

      def column(attribute)
        csv_row[self.class.columns[attribute]]
      end

      def postcode_without_spaces
        column(:postcode)&.gsub(" ", "")
      end

      def early_years_individual_registers
        raw_data = column(:early_years_individual_registers)

        case raw_data
        when "ALL"
          %w[CCR VCR EYR]
        when "CCR only"
          %w[CCR]
        when "CCR-VCR"
          %w[CCR VCR]
        when "EYR only"
          %w[EYR]
        when "EYR-CCR"
          %w[CCR EYR]
        when "EYR-VCR"
          %w[VCR EYR]
        when "VCR only"
          %w[VCR]
        else
          raise "Unknown Individual Register combinations value: #{raw_data}"
        end
      end

      def provider_early_years_register_flag
        column(:provider_early_years_register_flag) == "Y"
      end

      def provider_compulsory_childcare_register_flag
        column(:provider_compulsory_childcare_register_flag) == "Y"
      end
    end

    class ChildminderAgencyWrappedCSVRow
      attr_reader :csv_row

      def self.columns
        {
          provider_urn: "provider urn",
          provider_name: "provider name",
          provider_status: "provider status",
          address_1: "provider address line 1",
          address_2: "provider address line 2",
          address_3: "provider address line 3",
          postcode: "postcode",
          local_authority: "local authority",
          individual_register_combinations: "individual register combinations",
        }
      end

      def initialize(csv_row:)
        @csv_row = csv_row
      end

      def column(attribute)
        csv_row[self.class.columns[attribute]]&.strip
      end

      def postcode_without_spaces
        column(:postcode)&.gsub(" ", "")
      end

      def early_years_individual_registers
        raw_data = column(:individual_register_combinations)

        case raw_data
        when "EYR, CCR, VCR"
          %w[CCR VCR EYR]
        else
          raise "Unknown Individual Register combinations value: #{raw_data}"
        end
      end

      def provider_compulsory_childcare_register_flag
        nil
      end

      def provider_early_years_register_flag
        nil
      end
    end
  end
end
