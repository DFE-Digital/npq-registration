class Admin::UsersController < AdminController
  include Pagy::Backend

  def index
    @pagy, @users = pagy(scope)
  end

  def show
    @user = User.find(params[:id])
    @applications = @user.applications.order(:created_at, :id)
  end

private

  def scope
    AdminService::UsersSearch.new(q: params[:q]).call
  end
end
