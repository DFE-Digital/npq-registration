class Admin::AdminsController < SuperAdminController
  include Pagy::Backend

  def index
    @pagy, @users = pagy(scope)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.find_or_initialize_by(email: user_params[:email])
    @user.admin = true

    if @user.save
      redirect_to admin_admins_path
    else
      render :new
    end
  end

  def destroy
    @user = User.find(params[:id])

    if @user == current_user || @user.super_admin?
      flash[:error] = "You cannot remove admin permissions from yourself or another super admin."
    elsif @user.update(admin: false)
      redirect_to admin_admins_path
    else
      flash[:error] = "Failed to remove admin permissions from #{@user.email}, please contact technical support if this problem persists."
      redirect_back fallback_location: admin_admins_path
    end
  end

private

  def scope
    User.admins
  end

  def user_params
    params.require(:user).permit(:full_name, :email)
  end
end
