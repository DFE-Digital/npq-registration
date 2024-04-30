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
      flash[:success] = "New closed registration user added"
      redirect_to admin_closed_registration_users_path
    else
      flash[:error] = "Can not create a closed registration user"
      render :index
    end
  end

  def destroy
    @user = ClosedRegistrationUser.find(params[:id])
    if request.delete?
      Flipper.disable_actor(Feature::REGISTRATION_OPEN, @user)
      if @user.delete
        flash[:success] = "Closed registration user was daleted"
        redirect_to admin_closed_registration_users_path
      else
        flash[:error] = "Can not delete a closed registration user"
        render :index
      end
    end
  end
end
