class AccountsController < LoggedInController
  def show
    return unless current_user.applications.count == 1

    application = current_user.applications.first
    redirect_to accounts_user_registration_path(application)
  end
end
