class AdminController < ApplicationController
  before_action :require_admin

  def show
    @last_seven_days = Services::Admin::DashboardStats.new(start_time: 7.days.ago)
    @all_time = Services::Admin::DashboardStats.new
  end

private

  def require_admin
    unless current_user.admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
