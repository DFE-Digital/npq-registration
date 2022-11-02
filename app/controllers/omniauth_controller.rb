class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:tra_openid_connect]

  def tra_openid_connect
    @user = User.from_provider_data(request.env["omniauth.auth"])

    if @user.persisted?
      session["user_id"] = @user.id

      sign_in_and_redirect @user
    else
      flash[:error] = failure_message
      redirect_to failed_sign_in_path
    end
  end

  def failure
    flash[:error] = failure_message
    redirect_to failed_sign_in_path
  end

private

  def failure_message
    "An error was encountered saving your information, please try again in a few moments."
  end

  def registration_wizard_omniauth_step
    :start
  end

  def failed_sign_in_path
    registration_wizard_show_path(:get_an_identity)
  end

  def after_sign_in_path_for(user)
    wizard = RegistrationWizard.new(
      current_step: :get_an_identity_callback,
      store: session["registration_store"],
      params: {},
      request:,
      current_user: user,
    )

    registration_wizard_show_path(wizard.next_step_path)
  end
end
