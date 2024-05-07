class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    @pagy, @applications = pagy(applications_query.applications)
  end

  def show
    @application = applications_query.application(id: params[:id])
  end

private

  def applications_query
    @applications_query ||= Applications::Query.new
  end
end
