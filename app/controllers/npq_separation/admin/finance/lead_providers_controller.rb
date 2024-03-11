class NpqSeparation::Admin::Finance::LeadProvidersController < NpqSeparation::AdminController
  def index
    @lead_providers = LeadProviders::Find.new.all
  end

  def show
    @lead_provider = LeadProviders::Find.new.find_by_id(params[:id])
    @statements = Statements::Find.new.belonging_to(lead_provider: @lead_provider)
  end
end
