require "csv"

module Services
  module ApprovedIttProviders
    class Update
      attr_reader :file_name, :new_approved_records, :unapproved_records, :previously_approved_records

      def initialize(file_name:)
        @file_name = file_name
        @new_approved_records = 0
        @unapproved_records = 0
        @previously_approved_records = 0
      end

      def self.call(file_name:)
        new(file_name:).call
      end

      def call
        raise_not_found_error unless file_exists?

        update_itt_approved_providers
      end

    private

      def raise_not_found_error
        raise "File not found: #{file_name}"
      end

      def file_exists?
        File.exist?(file_name)
      end

      def update_itt_approved_providers
        approved_names = approved_itt_providers_legal_names

        CSV.foreach(file_name, headers: true, col_sep: ",") do |row|
          # Legal name is unique identifier
          legal_name = row["Legal accredited name"]

          # Checking approved providers if exists and skipping
          if approved_names.include?(legal_name)
            approved_names.delete(legal_name)

            next
          end

          # Now you will check if the provider has been previously
          # approved and also skip next stage
          previously_approved = IttProvider.find_by(legal_name:)

          if previously_approved
            previously_approved.update!(approved: true, removed_at: nil)
            @previously_approved_records += 1

            next
          end

          # Create new record if its new provider
          IttProvider.create!(legal_name: row["Legal accredited name"],
                              operating_name: row["Operating name"],
                              approved: true)
          @new_approved_records += 1
        end

        # Names left over after using CSV to update
        names_to_unapprove = approved_names
        @unapproved_records += names_to_unapprove.count

        names_to_unapprove.each do |legal_name|
          itt_provider = IttProvider.find_by(legal_name:)
          itt_provider.update!(approved: false, removed_at: Time.zone.now)
        end

        log_results
      end

      def approved_itt_providers_legal_names
        @approved_itt_providers_legal_names ||= IttProvider.currently_approved.pluck(:legal_name)
      end

      def log_results
        Rails.logger.info("Newly approved providers: #{new_approved_records}")
        Rails.logger.info("Unapproved providers: #{unapproved_records}")
        Rails.logger.info("Re-approved providers: #{previously_approved_records}")
      end
    end
  end
end
