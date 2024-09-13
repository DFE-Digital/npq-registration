class Accounts::UserRegistrationsController < AccountsController
  def show
    @application = current_user.applications.find(params[:id])
  end
end
