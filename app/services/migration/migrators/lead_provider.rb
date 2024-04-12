module Migration::Migrators
  class LeadProvider < Base
    def call
      migrate(ecf_npq_lead_providers, :lead_provider) do |ecf_npq_lead_provider|
        ::LeadProvider.find_by!(ecf_id: ecf_npq_lead_provider.id)
      end
    end

  private

    def ecf_npq_lead_providers
      @ecf_npq_lead_providers ||= Migration::Ecf::NpqLeadProvider.all
    end
  end
end
