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
      migrate(self.class.ecf_applications) do |application|
        provider_urn = application.private_childcare_provider_urn

        next if ::PrivateChildcareProvider.including_disabled.where(provider_urn:).exists?

        ::PrivateChildcareProvider.create!(provider_urn:, disabled_at: Time.zone.now)
      end
    end
  end
end
