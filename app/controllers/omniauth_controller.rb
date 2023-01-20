class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:tra_openid_connect]
  before_action :remove_from_get_an_identity_pilot, only: :tra_openid_connect, if: :tra_response_excludes_trn?

  def tra_openid_connect
    # Let user continue using current TRA login
    session.delete("clear_tra_login")

    provider_data = request.env["omniauth.auth"]

    @user = User.find_or_create_from_provider_data(
      provider_data,
      feature_flag_id: session["feature_flag_id"],
    )

    # @user.persisted? checks that it exists and has been persisted to the database
    # @user.save checks that any changes made to an existing record have been persisted to that persisted record
    if @user.persisted? && @user.save
      Services::Feature.enroll_user_in_get_an_identity_pilot(@user)
      session["user_id"] = @user.id

      sign_in_and_redirect @user
    else
      send_error_to_sentry(
        "Could not persist user after omniauth callback",
        contexts: {
          "Errors" => @user.errors.to_hash,
          "Provider" => {
            provider: provider_data.provider,
            uid: provider_data.uid,
          },
        },
      )

      flash[:error] = failure_message
      redirect_to failed_sign_in_path
    end
  end

  def failure
    send_error_to_sentry(
      "Omniauth login failure",
      contexts: {
        "Strategy" => { name: request.env["omniauth.error.strategy"].name },
        "Error" => { "omniauth.error.type" => request.env["omniauth.error.type"] },
      },
    )

    flash[:error] = failure_message
    redirect_to failed_sign_in_path
  end

private

  def send_error_to_sentry(message, contexts: {})
    Sentry.with_scope do |scope|
      contexts.each do |context_name, context|
        scope.set_context(context_name, context)
      end

      exception = RuntimeError.new(message)
      Sentry.capture_exception(exception)
    end
  end

  def failure_message
    "There was an error. Please try again in a few moments. If this problem persists, contact us at continuing-professional-development@digital.education.gov.uk"
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
    provider_data = request.env["omniauth.auth"]

    send_error_to_sentry(
      "User removed from Pilot",
      contexts: {
        status: {
          trn_blank: tra_response_excludes_trn?,
        },
        "Provider" => {
          provider: provider_data.provider,
          uid: provider_data.uid,
        },
      },
    )

    # Turn off the feature flag for this user
    Services::Feature.remove_user_from_get_an_identity_pilot(current_user)

    # Redirect to the page the user would have gone to if they hadn't been sent to the GAI
    # Since with the pilot flag enabled the provider-check question was skipped we need to redirect back to the
    # very beginning of the flow to ensure the user answers all questions
    redirect_to registration_wizard_show_path(:"provider-check")
  end
end
