class AdminService::UnsyncedApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(scope)
  end

private

  def scope
    Application.unsynced.joins(:user).eager_load(:user, :course, :lead_provider).order(created_at: :desc)
  end
end
