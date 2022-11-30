class Admin::UnsyncedApplicationsController < AdminController
  include Pagy::Backend

  def index
    @pagy, @applications = pagy(scope)
  end

  def show
    @application = Application.unsynced.includes(:user).find(params[:id])
  end

private

  def scope
    Application.unsynced.joins(:user).eager_load(:user, :course, :lead_provider)
  end
end
