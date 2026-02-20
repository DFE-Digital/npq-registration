class AdminController < ApplicationController
  layout "application"
  before_action :require_admin
  skip_before_action :authenticate_user!

private

  def require_admin
    unless current_admin
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
