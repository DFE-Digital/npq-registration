class Accounts::UserRegistrationsController < AccountsController
  before_action :set_application



private

  def set_application
    @application = current_user.applications.find(params[:id])
  end
end
