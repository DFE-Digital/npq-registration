class NpqSeparation::Admin::UsersController < NpqSeparation::AdminController
  def index
    @pagy, @users = pagy(scope)
  end

  def show
    @user = User.includes(applications: %i[course lead_provider school]).find(params[:id])
  end

private

  def scope
    AdminService::UsersSearch.new(q: params[:q]).call
  end
end
