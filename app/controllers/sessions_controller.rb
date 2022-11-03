class SessionsController < ApplicationController
  before_action :require_tra_login, only: :show

  def new; end

  def show; end

private

  def require_tra_login
    redirect_to new_session_path if current_user.blank?
  end
end
