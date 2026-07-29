class Admin::DeclarationsDashboardController < AdminController
  def show
    @lead_providers = LeadProvider.alphabetical
    @cohorts = Cohort.order_by_latest

    @declarations_filter = Admin::Dashboards::DeclarationsFilter.new(
      declarations_filter_params,
      submitted: params.key?(:declarations_filter),
    )
    @declarations_filter.valid? if @declarations_filter.submitted?
  end

private

  def declarations_filter_params
    params.fetch(:declarations_filter, {}).permit(:lead_provider_id, :cohort_id)
  end
end
