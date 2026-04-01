class AccountsController < LoggedInController
  include RegistrationWizardState

  def show
    return unless current_user.applications.count == 1

    application = current_user.applications.first
    redirect_to accounts_user_registration_path(application)
  end

private

  def wizard
    @wizard ||= Registration::Wizard.new(
      current_step: :start,
      current_step_params: {},
      state_store:,
    ).tap { |w| w.current_step.started = true }
  end
  helper_method :wizard
end
