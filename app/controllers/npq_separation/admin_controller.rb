class NpqSeparation::AdminController < ApplicationController
  before_action :require_admin

  def show; end

private

  def require_admin
    unless current_admin
      flash[:negative] = { title: "Unauthorized", text: "Sign in with your admininstrator account" }
      redirect_to sign_in_path
    end
  end
end
