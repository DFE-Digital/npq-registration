module Migration::Ecf::Finance
  class Statement < Migration::Ecf::BaseRecord
    self.inheritance_column = nil

    belongs_to :cohort
    belongs_to :cpd_lead_provider
    has_one :npq_lead_provider, through: :cpd_lead_provider

    default_scope { where("statements.type ilike ?", "Finance::Statement::NPQ%") }
  end
end
