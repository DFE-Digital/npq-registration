class SessionsController < ApplicationController
  def new
    render :new
  end

  def create
    user_info = request.env['omniauth.auth']
    flash[:success] = user_info
    redirect_to login_path
  end
end
