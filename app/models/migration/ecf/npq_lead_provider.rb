module Migration::Ecf
  class NpqLeadProvider < BaseRecord
    belongs_to :cpd_lead_provider, optional: true
    has_many :statements, through: :cpd_lead_provider, class_name: "Finance::Statement"
  end
end
