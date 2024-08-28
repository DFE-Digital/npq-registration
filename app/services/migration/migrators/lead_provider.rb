module Migration::Migrators
  class LeadProvider < Base
    class << self
      def record_count
        ecf_npq_lead_providers.count
      end

      def model
        :lead_provider
      end

      def ecf_npq_lead_providers
        Migration::Ecf::NpqLeadProvider
      end
    end

    def call
      migrate(self.class.ecf_npq_lead_providers) do |ecf_npq_lead_provider|
        ::LeadProvider.find_by!(ecf_id: ecf_npq_lead_provider.id)
      end
    end
  end
end
