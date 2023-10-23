class Admin::UsersController < AdminController
  include Pagy::Backend

  def index
    @pagy, @users = pagy(scope)
  end

  def show
    @user = User.find(params[:id])
  end

private

  def scope
    AdminService::UsersSearch.new(q: params[:q]).call
  end
end
