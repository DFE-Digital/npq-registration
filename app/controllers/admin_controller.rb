class AdminController < ApplicationController
  before_action :require_admin

  def show; end

private

  def require_admin
    unless current_user.admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with you admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
