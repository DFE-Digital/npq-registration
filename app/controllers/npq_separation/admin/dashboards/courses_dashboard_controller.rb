class NpqSeparation::Admin::Dashboards::CoursesDashboardController < NpqSeparation::AdminController
  def show
    @cohort = Cohort.find_by(id: params[:cohort_id]) || Cohort.current
    @applications = Application.where(cohort: @cohort)
  end
end
