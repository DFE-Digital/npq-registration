# frozen_string_literal: true

class AdminService::DeclarationsDashboard
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :lead_provider_id
  attribute :cohort_id

  validates :lead_provider_id, presence: true
  validates :cohort_id, presence: true

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: lead_provider_id)
  end

  def cohort
    @cohort ||= Cohort.find_by(id: cohort_id)
  end
end
