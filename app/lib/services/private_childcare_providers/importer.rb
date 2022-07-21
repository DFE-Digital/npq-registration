require "csv"

module Services
  module PrivateChildcareProviders
    class Importer
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
        wrapped_csv_row = csv_row_parser.new(csv_row:)

        new_record = false
        updated_record = false

        private_childcare_provider = PrivateChildcareProvider.find_or_initialize_by(provider_urn: wrapped_csv_row.provider_urn) do
          new_record = true
        end

        private_childcare_provider.assign_attributes(
          address_1: wrapped_csv_row.address_1,
          address_2: wrapped_csv_row.address_2,
          address_3: wrapped_csv_row.address_3,
          provider_status: wrapped_csv_row.provider_status,
          early_years_individual_registers: wrapped_csv_row.early_years_individual_registers,
          local_authority: wrapped_csv_row.local_authority,
          ofsted_region: wrapped_csv_row.ofsted_region,
          places: wrapped_csv_row.places,
          postcode: wrapped_csv_row.postcode,
          postcode_without_spaces: wrapped_csv_row.postcode_without_spaces,
          provider_compulsory_childcare_register_flag: wrapped_csv_row.provider_compulsory_childcare_register_flag,
          provider_early_years_register_flag: wrapped_csv_row.provider_early_years_register_flag,
          provider_name: wrapped_csv_row.provider_name,
          region: wrapped_csv_row.region,
          registered_person_name: wrapped_csv_row.registered_person_name,
          registered_person_urn: wrapped_csv_row.registered_person_urn,
          registration_date: wrapped_csv_row.registration_date,
          town: wrapped_csv_row.town,
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

      class ChildcareProviderWrappedCSVRow
        attr_reader :csv_row

        def initialize(csv_row:)
          @csv_row = csv_row
        end

        def provider_urn
          csv_row["Provider URN"]
        end

        def provider_name
          csv_row["Provider name"]
        end

        def registered_person_name
          csv_row["Registered_Person_Name"]
        end

        def registered_person_urn
          csv_row["Registered person URN"]
        end

        def registration_date
          csv_row["Registration date"]
        end

        def provider_status
          csv_row["Provider status"]
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

        def local_authority
          csv_row["Local authority"]
        end

        def ofsted_region
          csv_row["Ofsted region"]
        end

        def postcode_without_spaces
          postcode&.gsub(" ", "")
        end

        def early_years_individual_registers
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
          csv_row["Provider Early Years Register Flag"] == "Y"
        end

        def provider_compulsory_childcare_register_flag
          csv_row["Provider Compulsory Childcare Register Flag"] == "Y"
        end

        def places
          csv_row["Places"]
        end
      end

      class ChildminderAgencyWrappedCSVRow
        attr_reader :csv_row

        def initialize(csv_row:)
          @csv_row = csv_row
        end

        def retrieve_value(key)
          raw_value = csv_row[key]
          raw_value&.strip
        end

        def provider_urn
          retrieve_value("CA Reference")
        end

        def provider_name
          retrieve_value("Provider Name")
        end

        def registered_person_name
          nil
        end

        def registered_person_urn
          nil
        end

        def registration_date
          nil
        end

        def provider_status
          retrieve_value("Provider Status")
        end

        def address_1
          retrieve_value("Provider Address 1")
        end

        def address_2
          retrieve_value("Provider Address 2")
        end

        def address_3
          retrieve_value("Provider Address 3")
        end

        def town
          nil
        end

        def postcode
          retrieve_value("Provider Postcode")
        end

        def region
          nil
        end

        def local_authority
          retrieve_value("Local Authority")
        end

        def ofsted_region
          nil
        end

        def postcode_without_spaces
          postcode&.gsub(" ", "")
        end

        def early_years_individual_registers
          raw_data = retrieve_value("Individual Register Combinations")

          case raw_data
          when "EYR, CCR, VCR"
            %w[CCR VCR EYR]
          else
            raise "Unknown Individual Register combinations value: #{raw_data}"
          end
        end

        def provider_early_years_register_flag
          nil
        end

        def provider_compulsory_childcare_register_flag
          nil
        end

        def places
          nil
        end
      end
    end
  end
end
