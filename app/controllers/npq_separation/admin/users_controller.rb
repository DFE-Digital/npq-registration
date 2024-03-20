class NpqSeparation::Admin::UsersController < NpqSeparation::AdminController
  def index
    @pagy, @users = pagy(find_user.all)
  end

  def show
    @user = find_user.by_id(params[:id])
  end

private

  def find_user
    @find_user ||= Users::Find.new
  end
end
