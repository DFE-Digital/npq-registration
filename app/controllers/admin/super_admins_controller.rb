class Admin::SuperAdminsController < SuperAdminController
  def update
    @user = User.find(params[:id])

    if @user.update(super_admin: true)
      flash[:success] = t(".success", email: @user.email)
    else
      flash[:error] = t(".failure", email: @user.email)
    end

    redirect_back(fallback_location: admin_admins_path)
  end
end
