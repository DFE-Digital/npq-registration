class Admin::SettingsController < SuperAdminController
  def index
    @setting = Setting.first
  end

  def update
    @setting = Setting.find(params[:id])
    if @setting.update(params[:setting].permit(:course_start_date))
      flash[:success] = "Settings updated"
      redirect_to admin_settings_path
    else
      flash[:errork] = "Settings can not be updated"
      render :index
    end
  end
end
