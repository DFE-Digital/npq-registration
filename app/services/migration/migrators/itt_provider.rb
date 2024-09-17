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
      migrate(self.class.ecf_applications) do |application|
        itt_provider = application.itt_provider

        next if ::IttProvider.including_disabled.where("legal_name ILIKE ? OR operating_name ILIKE ?", itt_provider, itt_provider).exists?

        ::IttProvider.create!(operating_name: itt_provider, legal_name: itt_provider, disabled_at: Time.zone.now)
      end
    end
  end
end
