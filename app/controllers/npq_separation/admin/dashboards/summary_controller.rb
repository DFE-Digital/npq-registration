class NpqSeparation::Admin::Dashboards::SummaryController < NpqSeparation::AdminController
  def show
    @applications = Application.where(cohort: Cohort.current)
  end
end
