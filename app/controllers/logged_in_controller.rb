class LoggedInController < ApplicationController
private

  def authenticate_user!
    redirect_to sign_in_path unless current_user
  end
end
