module Migration::Ecf
  class LeadProvider < BaseRecord
    self.table_name = "npq_lead_providers"

    has_many :statements, primary_key: "cpd_lead_provider_id", foreign_key: "cpd_lead_provider_id"
  end
end
