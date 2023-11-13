class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:tra_openid_connect]

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
      session["user_id"] = @user.id
      Ecf::EcfUserUpdater.new(user: @user).call if @user.ecf_id.present?

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

  def failed_sign_in_path
    registration_wizard_show_path(:start)
  end

  def after_sign_in_path_for(user)
    return account_path if user.applications.any?

    start_questionnaire_path(user)
  end

  def start_questionnaire_path(user)
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
