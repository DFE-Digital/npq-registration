# class NpqSeparation::Admin::AdminsController < ApplicationController
#   def index = head(:method_not_allowed)
# end

class NpqSeparation::Admin::AdminsController < NpqSeparation::AdminController
  before_action :require_super_admin

  include Pagy::Backend

  def index
    @pagy, @admins = pagy(Admin.all)
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.find_or_initialize_by(email: admin_params[:email])
    @admin.assign_attributes(admin_params)

    if @admin.save
      flash[:success] = "Admin permissions granted to #{@admin.email}"
      redirect_to npq_separation_admin_admins_path
    else
      render :new
    end
  end

  def destroy
    @admin = Admin.find(params[:id])

    if @admin == current_admin || @admin.super_admin?
      flash[:error] = "You cannot remove admin permissions from yourself or another super admin."
      redirect_back fallback_location: npq_separation_admin_admins_path
    elsif @admin.destroy!
      redirect_to npq_separation_admin_admins_path, flash: { success: "#{@admin.full_name} deleted" }
    else
      flash[:error] = "Failed to remove admin permissions from #{@admin.email}, please contact technical support if this problem persists."
      redirect_back fallback_location: npq_separation_admin_admins_path
    end
  end

  private

  def admin_params
    params.require(:admin).permit(:full_name, :email)
  end
end
