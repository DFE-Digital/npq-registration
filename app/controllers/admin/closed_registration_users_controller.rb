class Admin::ClosedRegistrationUsersController < AdminController
  def index
    @users = ClosedRegistrationUser.all
    @user = ClosedRegistrationUser.new
  end

  def new
    @user = ClosedRegistrationUser.new
  end

  def create
    @user = ClosedRegistrationUser.new(params[:closed_registration_user].permit(:email))
    if @user.save
      flash[:success] = "New closed registration user created"
      redirect_to admin_closed_registration_users_path
    else
      flash[:error] = "Can not create a user"
      render :index
    end
  end
end
