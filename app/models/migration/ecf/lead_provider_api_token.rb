# frozen_string_literal: true

module Migration::Ecf
  class LeadProviderAPIToken < APIToken
    belongs_to :lead_provider, optional: true
    belongs_to :cpd_lead_provider, optional: true

    def owner
      cpd_lead_provider
    end

    def owner_description
      "CPD lead provider: #{cpd_lead_provider.name}"
    end

    def readonly?
      false
    end
  end
end
