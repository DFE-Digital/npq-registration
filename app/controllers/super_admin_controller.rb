class SuperAdminController < AdminController
  before_action :require_super_admin

private

  def require_super_admin
    unless current_user.super_admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
