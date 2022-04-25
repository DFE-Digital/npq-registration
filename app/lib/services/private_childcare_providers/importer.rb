require "csv"

module Services
  module PrivateChildcareProviders
    class Importer
      attr_reader :file_name, :import_errors, :imported_records

      def initialize(file_name:)
        @file_name = file_name
        @import_errors = {}
        @imported_records = 0
      end

      def call
        raise_not_found_error unless file_exists?

        CSV.foreach(file_name, **csv_options).with_index(&method(:persist_csv_row))
      end

    private

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
        }
      end

      def file
        @file ||= CSV.open(file_name)
      end

      PROVIDER_URN_HEADER_NAME = "Provider URN".freeze

      def persist_csv_row(csv_row, row_number)
        wrapped_csv_row = WrappedCSVRow.new(csv_row: csv_row)

        new_record = false
        PrivateChildcareProvider.find_or_create_by!(urn: wrapped_csv_row.urn) do |private_childcare_provider|
          new_record = true

          private_childcare_provider.assign_attributes(
            name: wrapped_csv_row.name,
            establishment_status_code: wrapped_csv_row.establishment_status_code,
            establishment_status_name: wrapped_csv_row.establishment_status_name,
            address_1: wrapped_csv_row.address_1,
            address_2: wrapped_csv_row.address_2,
            address_3: wrapped_csv_row.address_3,
            town: wrapped_csv_row.town,
            postcode: wrapped_csv_row.postcode,
            region: wrapped_csv_row.region,
            postcode_without_spaces: wrapped_csv_row.postcode_without_spaces,
            early_years_individual_registers: wrapped_csv_row.individual_registers,
            provider_early_years_register_flag: wrapped_csv_row.provider_early_years_register_flag,
            provider_compulsory_childcare_register_flag: wrapped_csv_row.provider_compulsory_childcare_register_flag,
            places: wrapped_csv_row.places,
          )
        end

        @imported_records += 1 if new_record
      rescue StandardError => e
        # I've adjusted the row in the error here so that it'll properly line up with spreadsheeting software
        # when hunting for errors.
        # It's +2 because we need +1 to account for headers, and +1 to account for with_index being zero based.
        row_number_for_errors = row_number + 2
        @import_errors[row_number_for_errors] = []
        @import_errors[row_number_for_errors] << e.message
      end

      class WrappedCSVRow
        attr_reader :csv_row

        def initialize(csv_row:)
          @csv_row = csv_row
        end

        def urn
          # We use Provider URN rather than Registered person URN because
          # the former is always present whilst the latter is sometimes redacted.
          # We need a URN so we have to use the column that is always populated
          csv_row["Provider URN"]
        end

        def name
          csv_row["Provider name"]
        end

        def establishment_status_code
          return unless csv_row["Provider status"] == "Active"

          1
        end

        def establishment_status_name
          {
            1 => "Open",
          }[establishment_status_code]
        end

        def address_1
          csv_row["Provider address line 1"]
        end

        def address_2
          csv_row["Provider address line 2"]
        end

        def address_3
          csv_row["Provider address line 3"]
        end

        def town
          csv_row["Provider town"]
        end

        def postcode
          csv_row["Postcode"]
        end

        def region
          csv_row["Region"]
        end

        def postcode_without_spaces
          csv_row["Postcode"]&.gsub(" ", "")
        end

        def individual_registers
          raw_data = csv_row["Individual Register combinations"]

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
          csv_row["Provider Early Years Register Flag"] == 'Y'
        end

        def provider_compulsory_childcare_register_flag
          csv_row["Provider Compulsory Childcare Register Flag"] == 'Y'
        end

        def places
          csv_row["Places"]
        end
      end
    end
  end
end
