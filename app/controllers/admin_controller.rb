class AdminController < ApplicationController
  layout "application"
  before_action :require_admin

  def show
    @last_seven_days = AdminService::DashboardStats.new(start_time: 7.days.ago)
    @all_time = AdminService::DashboardStats.new
  end

private

  def require_admin
    unless current_admin
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
