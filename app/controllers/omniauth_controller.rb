class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:tra_openid_connect]
  before_action :remove_from_get_an_identity_pilot, only: :tra_openid_connect, if: :tra_response_excludes_trn?

  def tra_openid_connect
    @user = User.find_or_create_from_provider_data(
      request.env["omniauth.auth"],
      feature_flag_id: session["feature_flag_id"],
    )

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

  def tra_response_excludes_trn?
    request.env["omniauth.auth"].info.trn.blank?
  end

  def remove_from_get_an_identity_pilot
    # Turn off the feature flag for this user
    Services::Feature.remove_user_from_get_an_identity_pilot(current_user)

    # Redirect to the page the user would have gone to if they hadn't been sent to the GAI
    # Since with the pilot flag enabled the provider-check question was skipped we need to redirect back to the
    # very beginning of the flow to ensure the user answers all questions
    redirect_to registration_wizard_show_path(:"provider-check")
  end
end
