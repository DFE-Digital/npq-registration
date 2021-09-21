class AdminController < ApplicationController
  before_action :require_admin

  def show; end

private

  def require_admin
    unless current_user.admin?
      redirect_to sign_in_path
    end
  end
end
