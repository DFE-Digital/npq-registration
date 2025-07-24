class NpqSeparation::Admin::Dashboards::ProvidersDashboardController < NpqSeparation::AdminController
  def show
    if params[:cohort_id].present?
      @cohort = Cohort.find_by(id: params[:cohort_id])
      @applications = Application.where(cohort: @cohort)
    else
      @applications = Application
    end
  end
end
