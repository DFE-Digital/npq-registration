module Migration::Ecf
  class CpdLeadProvider < BaseRecord
    has_one :npq_lead_provider
    has_many :statements, class_name: "Finance::Statement"
  end
end
