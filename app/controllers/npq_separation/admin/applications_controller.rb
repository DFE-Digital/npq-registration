class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    applications = Application.includes(:private_childcare_provider, :school, :user)
                              .merge(filter_scope)
                              .merge(search_scope)
                              .order("applications.created_at ASC")

    @pagy, @applications = pagy(applications)
  end

  def show
    @application = applications_query.application(id: params[:id])
    @declarations = @application.declarations
                                .includes(:lead_provider, :cohort, :participant_outcomes, :statements)
                                .order(created_at: :asc, id: :asc)
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

  def applications_query
    @applications_query ||= Applications::Query.new
  end

  def filter_scope
    Application.where(filter_params.compact_blank)
  end

  def search_scope
    @search_scope ||= Applications::Search.search(params[:q])
  end
end
