class NpqSeparation::Admin::ActionsLogController < NpqSeparation::AdminController
  def search
    admin_user_id = params[:admin_user_id]
    if admin_user_id.blank?
      redirect_to npq_separation_admin_actions_log_path
    else
      redirect_to npq_separation_admin_actions_log_admin_user_path(params[:admin_user_id])
    end
  end

  def show_admin_user
    @admin = Admin.find(params[:id])
    versions = PaperTrail::Version
      .includes(:item)
      .where(item_type: "Application", whodunnit: "Admin #{@admin.id}")
      .order(created_at: :desc)
    @pagy, @versions = pagy(versions)
  end
end
