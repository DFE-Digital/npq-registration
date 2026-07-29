class Admin::DeclarationsDashboardController < AdminController
  helper_method :submitted?

  def show
    @lead_providers = LeadProvider.alphabetical
    @cohorts = Cohort.order_by_latest

    @declarations_dashboard = AdminService::DeclarationsDashboard.new(declarations_dashboard_params)
    @show_results = submitted? && @declarations_dashboard.valid?
  end

private

  def submitted?
    params.key?(:declarations_dashboard)
  end

  def declarations_dashboard_params
    params.fetch(:declarations_dashboard, {}).permit(:lead_provider_id, :cohort_id)
  end
end
