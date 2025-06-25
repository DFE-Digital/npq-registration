class NpqSeparation::AdminController < ApplicationController
  layout "admin"
  before_action :require_admin
  skip_before_action :authenticate_user!

  include Pagy::Backend

private

  def require_admin
    unless current_admin
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your administrator account" }
      redirect_to sign_in_path
    end
  end

  def require_super_admin
    unless current_admin.super_admin?
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your administrator account" }
      redirect_to sign_in_path
    end
  end
end
