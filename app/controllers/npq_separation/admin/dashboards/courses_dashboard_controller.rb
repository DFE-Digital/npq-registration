class NpqSeparation::Admin::Dashboards::CoursesDashboardController < NpqSeparation::AdminController
  def show
    if params[:cohort_id].present?
      @cohort = Cohort.find_by(id: params[:cohort_id])
      # we add condition ie. only one cohort
      @applications = Application.where(cohort: @cohort)
    else
      # we add condition ie. only one cohort
      @applications = Application
    end

    # this splits application to course and counts how many of application is per course
    #
    # Eg. `[1,2,3,3,2,4,5].tally`
    @rows = @applications.joins(:course).pluck("courses.name").tally.sort
  end
end
