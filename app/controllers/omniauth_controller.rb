class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:tra_openid_connect]

  def tra_openid_connect
    @user = User.from_provider_data(request.env["omniauth.auth"])

    if @user.persisted?
      session["user_id"] = @user.id

      sign_in_and_redirect @user
    else
      flash[:error] = "There was a problem signing you in through TRA."
      redirect_to new_session_path
    end
  end

  def failure
    flash[:error] = "There was a problem signing you in."
    redirect_to new_session_path
  end

private

  def after_sign_in_path_for(_user)
    session_path
  end
end
