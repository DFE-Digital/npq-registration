class LoggedInController < ApplicationController
private

  def authenticate_user!
    if current_user.null_user?
      redirect_to sign_in_path
    end
  end
end
