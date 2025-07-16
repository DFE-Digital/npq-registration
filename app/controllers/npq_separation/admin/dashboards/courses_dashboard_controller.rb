class NpqSeparation::Admin::Dashboards::CoursesDashboardController < NpqSeparation::AdminController
  def show
    @applications = Application.where(cohort: Cohort.current)
  end
end
