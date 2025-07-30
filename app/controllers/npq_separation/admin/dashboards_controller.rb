class NpqSeparation::Admin::DashboardsController < NpqSeparation::AdminController

  def index
  end

  def show
    @dashboard = params[:name]
    if params[:cohort_id].present?
      @cohort = Cohort.find_by(id: params[:cohort_id])
      @applications = Application.where(cohort: @cohort)
    else
      @applications = Application
    end
  end
end
