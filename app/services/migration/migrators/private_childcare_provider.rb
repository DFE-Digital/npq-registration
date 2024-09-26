module Migration::Migrators
  class PrivateChildcareProvider < Base
    class << self
      def record_count
        ecf_applications.count
      end

      def model
        :private_childcare_provider
      end

      def ecf_applications
        Migration::Ecf::NpqApplication.where.not(private_childcare_provider_urn: nil)
      end
    end

    def call
      migrate(self.class.ecf_applications) do |ecf_applications|
        ecf_applications.each do |ecf_application|
          provider_urn = ecf_application.private_childcare_provider_urn

          provider_exists = ::PrivateChildcareProvider.including_disabled.where(provider_urn:).exists?

          unless provider_exists
            ::PrivateChildcareProvider.create!(provider_urn:, disabled_at: Time.zone.now)
          end

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_application, e)
        end
      end
    end
  end
end
