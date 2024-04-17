class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    @pagy, @applications = pagy(Applications::Query.new.applications)
  end
end
