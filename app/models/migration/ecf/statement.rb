module Migration::Ecf
  class Statement < BaseRecord
    self.inheritance_column = nil

    belongs_to :cohort
    belongs_to :lead_provider, primary_key: "cpd_lead_provider_id", foreign_key: "cpd_lead_provider_id"

    default_scope { where("statements.type ilike ?", "Finance::Statement::NPQ%") }
  end
end
