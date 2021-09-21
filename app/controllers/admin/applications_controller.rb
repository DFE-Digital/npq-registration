class Admin::ApplicationsController < AdminController
  include Pagy::Backend

  def index
    scope = Application.includes(:user, :course, :lead_provider)

    if params[:q]
      scope = scope.joins(:user)
      scope = scope.where("users.email ilike ?", "%#{params[:q]}%")
    end

    @pagy, @applications = pagy(scope)
  end

  def show
    @application = Application.includes(:user).find(params[:id])
  end
end
