class NpqSeparation::Admin::ActionsLogController < NpqSeparation::AdminController
  def search
    if params[:admin_id].blank?
      redirect_to npq_separation_admin_actions_log_index_path
    else
      redirect_to npq_separation_admin_actions_log_path(params[:admin_id])
    end
  end

  def show
    @admin = Admin.find(params[:id])
    versions = PaperTrail::Version
      .includes(:item)
      .where(item_type: "Application", whodunnit: "Admin #{@admin.id}")
      .order(created_at: :desc)
    @pagy, @versions = pagy(versions)
  end
end
