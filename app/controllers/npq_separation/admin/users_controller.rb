class NpqSeparation::Admin::UsersController < NpqSeparation::AdminController
  def index
    @pagy, @users = pagy(scope)
  end

  def show
    @user = User.find(params[:id])
    @applications = @user.applications.includes(:course, :lead_provider, :school).order(:created_at, :id)
  end

private

  def scope
    AdminService::UsersSearch.new(q: params[:q]).call
  end
end
