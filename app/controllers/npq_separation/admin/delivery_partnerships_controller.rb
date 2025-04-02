class NpqSeparation::Admin::DeliveryPartnershipsController < NpqSeparation::AdminController
  def edit
    @delivery_partner = DeliveryPartner.find(params[:delivery_partner_id])
    @lead_providers = LeadProvider.all.order(:name)
    @cohorts = Cohort.all.order(created_at: :desc)
  end
end
