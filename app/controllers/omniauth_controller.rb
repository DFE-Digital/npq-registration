class OmniauthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token

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
      @user.set_closed_registration_feature_flag
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
  rescue StandardError => e
    id = @user.try(:id)
    Rails.logger.info("[GAI] #{e} raised, user_id=#{id} uid=#{try_to_extract_user_uid}")

    raise e
  end

  def failure
    redirect_to after_sign_in_path_for(current_user) and return if logged_in_user.present?

    Rails.logger.info("[GAI][omniauth_failure] uid=#{try_to_extract_user_uid} error=#{try_to_extract_error_type}")
    send_error_to_sentry(
      "Omniauth login failure",
      contexts: {
        "Strategy" => { name: request.env["omniauth.error.strategy"].name },
        "Error" => { "omniauth.error.type" => Base64.encode64(request.env["omniauth.error.type"].to_s) },
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
    if request.env["omniauth.params"] &&
        request.env["omniauth.params"]["request_email_updates"] == "true"
      return new_email_update_path
    end

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

  def try_to_extract_user_uid
    request.env["omniauth.auth"].uid
  rescue StandardError
    "unknown-provider-uid"
  end

  def try_to_extract_error_type
    request.env["omniauth.error.type"]
  rescue StandardError
    "unknown-error-type"
  end
end
