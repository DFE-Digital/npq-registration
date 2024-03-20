class NpqSeparation::Admin::ApplicationsController < NpqSeparation::AdminController
  def index
    @pagy, @applications = pagy(Applications::Find.new.all)
  end
end
