class Admin::SuperAdminsController < SuperAdminController
  def update
    @admin = Admin.find(params[:id])

    if @admin.update(super_admin: true)
      flash[:success] = t(".success", email: @admin.email)
    else
      flash[:error] = t(".failure", email: @admin.email)
    end

    redirect_back(fallback_location: admin_admins_path)
  end
end
