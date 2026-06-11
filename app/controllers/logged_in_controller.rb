class LoggedInController < ApplicationController
private

  def authenticate_user!
    redirect_to root_path unless current_user
  end
end
