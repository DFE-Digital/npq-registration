class Admin::UnsyncedApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(scope)
  end

private

  def scope
    Application.unsynced.joins(:user).eager_load(:user, :course, :lead_provider)
  end
end
