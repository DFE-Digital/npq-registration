require "csv"

module Services
  module ApprovedIttProviders
    class Update
      attr_reader :file_name

      def initialize(file_name:)
        @file_name = file_name
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
          legal_name = row["Legal accredited name"]
          if approved_names.include?(legal_name)
            approved_names.delete(legal_name)
            next
          end

          previously_approved = IttProvider.find_by(legal_name:)

          if previously_approved
            previously_approved.update!(approved: true, removed: nil)
            next
          end

          IttProvider.create!(legal_name: row["Legal accredited name"],
                              operating_name: row["Operating name"],
                              added: Time.zone.now,
                              approved: true)
        end
        # legal_names left over after using csv to update
        names_to_unapprove = approved_names

        names_to_unapprove.each do |legal_name|
          itt_provider = IttProvider.find_by(legal_name:)
          itt_provider.update!(approved: false, removed: Time.zone.now)
        end
      end

      def approved_itt_providers_legal_names
        @approved_itt_providers_legal_names ||= IttProvider.currently_approved.pluck(:legal_name)
      end
    end
  end
end
