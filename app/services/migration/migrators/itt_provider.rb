module Migration::Migrators
  class IttProvider < Base
    class << self
      def record_count
        ecf_applications.count
      end

      def model
        :itt_provider
      end

      def ecf_applications
        Migration::Ecf::NpqApplication.where.not(itt_provider: nil)
      end
    end

    def call
      migrate(self.class.ecf_applications) do |ecf_applications|
        ecf_applications.each do |ecf_application|
          itt_provider = ecf_application.itt_provider

          provider_exists = ::IttProvider.including_disabled.where("legal_name ILIKE ? OR operating_name ILIKE ?", itt_provider, itt_provider).exists?

          unless provider_exists
            ::IttProvider.create!(operating_name: itt_provider, legal_name: itt_provider, disabled_at: Time.zone.now)
          end

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_application, e)
        end
      end
    end
  end
end
