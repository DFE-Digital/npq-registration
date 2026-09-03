class Admin::DeclarationsDashboardController < AdminController
  def show
    @lead_providers = LeadProvider.alphabetical
    @cohorts = Cohort.order_by_latest

    @declarations_dashboard = AdminService::DeclarationsDashboard.new(declarations_dashboard_params)
    @show_results = submitted? && @declarations_dashboard.valid?

    if @show_results
      @calculator = Declarations::DashboardCalculator.new(
        lead_provider: @declarations_dashboard.lead_provider,
        cohort: @declarations_dashboard.cohort,
      )
    end
  end

private

  def submitted?
    params.key?(:declarations_dashboard)
  end

  def declarations_dashboard_params
    params.fetch(:declarations_dashboard, {}).permit(:lead_provider_id, :cohort_id)
  end
end
