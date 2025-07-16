class NpqSeparation::Admin::Dashboards::ProvidersDashboardController < NpqSeparation::AdminController
  def show
    @applications = Application.where(cohort: Cohort.current)
  end
end
