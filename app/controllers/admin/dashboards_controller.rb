class Admin::DashboardsController < AdminController
  def show
    @dashboard = params[:name]

    if @dashboard == "declarations-dashboard"
      build_declarations_filter
    elsif params[:cohort_id].present?
      @cohort = Cohort.find_by(id: params[:cohort_id])
      @applications = Application.where(cohort: @cohort)
    else
      @applications = Application
    end
  end

private

  def build_declarations_filter
    @lead_providers = LeadProvider.alphabetical
    @cohorts = Cohort.order_by_latest

    @declarations_filter = Admin::Dashboards::DeclarationsFilter.new(
      declarations_filter_params,
      submitted: params.key?(:declarations_filter),
    )
    @declarations_filter.valid? if @declarations_filter.submitted?
  end

  def declarations_filter_params
    params.fetch(:declarations_filter, {}).permit(:lead_provider_id, :cohort_id)
  end
end
