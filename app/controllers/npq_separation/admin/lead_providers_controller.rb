class NpqSeparation::Admin::LeadProvidersController < NpqSeparation::AdminController
  def index
    @lead_providers = LeadProviders::Find.new.all
  end

  def show
    @lead_provider = LeadProviders::Find.new.find_by_id(params[:id])
    @cohort = Cohort.order(start_year: :desc).first
    redirect_to npq_separation_admin_lead_provider_cohort_path(@lead_provider, @cohort)
  end
end
