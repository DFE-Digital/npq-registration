def create_matching_ecf_lead_providers
  LeadProvider.all.find_each do |lead_provider|
    create(:ecf_migration_npq_lead_provider, id: lead_provider.ecf_id)
  end
end
