class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    applications = Application.includes(:private_childcare_provider, :school, :user)
                              .merge(filter_scope)
                              .merge(search_scope)
                              .order("applications.created_at DESC")

    @pagy, @applications = pagy(applications)
  end

  def show
    @application = Application.find(params[:id])
  end

private

  def filter_params
    params.permit %i[
      training_status
      lead_provider_approval_status
      cohort_id
      work_setting
    ]
  end

  def filter_scope
    Application.where(effective_filter_params)
  end

  def default_cohort
    @default_cohort ||= Cohort.current
  end
  helper_method :default_cohort

  def effective_filter_params
    result = filter_params.compact_blank

    if params[:cohort_id] == "all"
      result.delete(:cohort_id)
    elsif result[:cohort_id].blank? && default_cohort
      result[:cohort_id] = default_cohort.id
    end

    result
  end

  def search_scope
    Applications::Search.search(params[:q])
  end
end
