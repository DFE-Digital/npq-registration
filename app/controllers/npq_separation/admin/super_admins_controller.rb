class NpqSeparation::Admin::SuperAdminsController < NpqSeparation::AdminController
  before_action :require_super_admin
  def update
    @admin = Admin.find(params[:id])
    if @admin.update(super_admin: true)
      flash[:success] = t(".success", email: @admin.email)
    else
      flash[:error] = t(".failure", email: @admin.email)
    end
    redirect_back(fallback_location: npq_separation_admin_admins_path)
  end
end
