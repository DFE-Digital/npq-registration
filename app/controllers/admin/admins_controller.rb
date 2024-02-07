class Admin::AdminsController < SuperAdminController
  include Pagy::Backend

  def index
    @pagy, @admins = pagy(Admin.all)
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.find_or_initialize_by(email: user_params[:email])
    @admin.assign_attributes(user_params)
    @admin.admin = true

    if @admin.save
      flash[:success] = "Admin permissions granted to #{@admin.email}"
      redirect_to admin_admins_path
    else
      render :new
    end
  end

  def destroy
    @admin = Admin.find(params[:id])

    if @admin == current_admin || @admin.super_admin?
      flash[:error] = "You cannot remove admin permissions from yourself or another super admin."
      redirect_back fallback_location: admin_admins_path
    elsif @admin.update(admin: false) # we should just delete the record here instead
      redirect_to admin_admins_path
    else
      flash[:error] = "Failed to remove admin permissions from #{@admin.email}, please contact technical support if this problem persists."
      redirect_back fallback_location: admin_admins_path
    end
  end

private

  def user_params
    params.require(:admin).permit(:full_name, :email)
  end
end
