class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    applications = Application.includes(:private_childcare_provider, :school, :user)
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

  def applications_query
    @applications_query ||= Applications::Query.new
  end

  def search_scope
    @search_scope ||= Applications::Search.search(params[:q])
  end
end
